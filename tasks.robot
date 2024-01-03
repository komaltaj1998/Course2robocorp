*** Settings ***
Documentation       Insert orders to system from a csv-file, produce receipts and a summary ZIP

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.PDF
Library             RPA.HTTP
Library             RPA.Tables
Library             OperatingSystem
Library             DateTime
Library             Dialogs
Library             Screenshot
Library             RPA.Archive
Library             RPA.Robocorp.Vault


*** Variables ***
${URL}             https://robotsparebinindustries.com/orders.csv
${receipt_directory}    ${OUTPUT_DIR}${/}receipts\\
${image_directory}      ${OUTPUT_DIR}${/}images/
${zip_directory}        ${OUTPUT_DIR}${/}
*** Tasks ***
Insert orders to system, produce receipts and a summary ZIP
    Get csv url
    Open the order website
    Fill in the order form using the data from the csv file
    Name and make the ZIP
    Delete original images
    Log out and close the browser

*** Keywords ***
Get csv url
    Download the csv file    ${URL}
Download the csv file
    [Arguments]    ${URL}
    Download    ${URL}    overwrite=True

Open the order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order
    Wait Until Page Contains Element    class:alert-buttons
    Click Button    OK

Click OK
    Wait Until Page Contains Element    class:alert-buttons
    Click Button    OK
Make order
    Click Button    Order
    Page Should Contain Element    id:receipt

Return to order form
    Wait Until Element Is Visible    id:order-another
    Click Button    id:order-another
Fill out 1 order
    [Arguments]    ${orders}
    Log     ${orders}[Head]
    Log     ${orders}[Body]
    Select From List By Index    //*[@id="head"]    ${orders}[Head]
    Select Radio Button    body    ${orders}[Body]
    Input Text    xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${orders}[Legs]
    Input Text    address    ${orders}[Address] 
    Wait Until Keyword Succeeds    2min    500ms    Make order
  
#Fill out 1 order
    #[Arguments]    ${orders}
    #Click OK
    #Wait Until Page Contains Element    class:form-group
    #Select From List By Index    head    ${orders}[Head]
    #Select Radio Button    body    ${orders}[Body]
    #Input Text    xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${orders}[Legs]
    #Input Text    address    ${orders}[Address]
    #Click Button    Preview
   # Wait Until Keyword Succeeds    2min    500ms    Make order

Save order details
    Wait Until Element Is Visible    id:receipt
    ${order_id}=    Get Text    //*[@id="receipt"]/p[1]
    ${receipt_filename}    Set Variable    ${receipt_directory}receipt_${order_id}.pdf
    Set Local Variable    ${receipt_filename}    ${receipt_directory}receipt_${order_id}.pdf
   # Set Local Variable    ${receipt_filename}    ${receipt_directory}receipt_${order_id}.pdf
    ${receipt_html}=    Get Element Attribute    //*[@id="receipt"]    outerHTML
    Html To Pdf    ${receipt_html}    ${receipt_filename}
    Wait Until Element Is Visible    id:robot-preview-image
    ${image_filename}    Set Variable    value
    Set Local Variable    ${image_filename}    ${image_directory}robot_${order_id}.png
    Screenshot    id:robot-preview-image    ${image_filename}
    Combine receipt with robot image to a PDF    ${receipt_filename}    ${image_filename}
Fill in the order form using the data from the csv file
    ${orders}=    Read table from CSV    orders.csv
    FOR    ${order}    IN    @{orders}
        Fill out 1 order    ${order}
        Save order details
        Return to order form
        Log    message=done
        Click Button    OK
    END
Combine receipt with robot image to a PDF
    [Arguments]    ${receipt_filename}    ${image_filename}
    Open Pdf    ${receipt_filename}
    @{pseudo_file_list}=    Create List    ${receipt_filename}    ${image_filename}:align=center
    Add Files To Pdf    ${pseudo_file_list}    ${receipt_filename}    ${FALSE}
    Close Pdf    ${receipt_filename}


Log out and close the browser
    Close Browser

Delete original images
    Empty Directory    ${image_directory}
    Empty Directory    ${receipt_directory}

Name and make the ZIP
    ${date}=    Get Current Date    exclude_millis=True
    ${name_of_zip}=    Get Value From User    Give the name for the zip of the orders:
    Log To Console    ${name_of_zip}_${date}
    Create the ZIP    ${name_of_zip}

Create the ZIP
    [Arguments]    ${name_of_zip}
    Create Directory    ${zip_directory}
    Archive Folder With Zip    ${receipt_directory}    ${zip_directory}${name_of_zip}
    Log    ${zip_directory}${name_of_zip}
