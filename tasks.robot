*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium  
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.Excel.Files
Library           RPA.PDF
Library           OperatingSystem
Library           RPA.Archive
Library           RPA.Dialogs
Library           RPA.Robocloud.Secrets
Library           RPA.Robocorp.Vault

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Startup
    Open the robot order website
    Submit Popup
    Download the CSV file
    Fill the form using the data from the Excel file
    Create ZIP file of all receipts
    Close Down

*** Variables ***
@{Or}=            Order
${receiptsDir}=         ${CURDIR}${/}Receipts

*** Keywords ***
Startup
    Create Directory    ${receiptsDir}

Open the robot order website
    Open Chrome Browser    https://robotsparebinindustries.com/#/robot-order

Submit Popup
    # Close the annoying modal
    Wait Until Page Contains Element    class:modal-content
    Click Button    OK

Download the CSV file
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True

Order
    Click Element When Visible      id:order
    Wait Until Element Is Visible   id:receipt

Fill and submit the form for one order
    # Fill the form
    [Arguments]    ${order}
    Select From List By Value    head    ${order}[Head]
    Click Element    //label[./input[@value="${order}[Body]"]]
    Input Text    css:form > .form-group:nth-child(3) > input    ${order}[Legs]
    Input Text    address    ${order}[Address]
    # Preview the robot
    Click Element When Visible  id:preview
    # Submit the order
    Wait Until Keyword Succeeds    10x   1 sec    Order
    # Store the receipt as a PDF file
    ${order_results_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${order_results_html}    ${OUTPUT_DIR}${/}order_results${order}[Order number].pdf
    # Take a screenshot of the robot
    Wait Until Page Contains Element    id:robot-preview-image
    Screenshot    id:robot-preview    ${OUTPUT_DIR}${/}order_summary${order}[Order number].png
    # Embed the robot screenshot to the receipt PDF file
    # Open Pdf    ${OUTPUT_DIR}${/}order_results${order}[Order number].pdf
    ${robotPNG}=     Create List    ${OUTPUT_DIR}${/}order_summary${order}[Order number].png:align=center
    ...     ${OUTPUT_DIR}${/}order_results${order}[Order number].pdf
    Add Files To Pdf    ${robotPNG}     ${OUTPUT_DIR}${/}order_results${order}[Order number].pdf
    # Close Pdf   ${OUTPUT_DIR}${/}order_results${order}[Order number].pdf
    Move File    ${OUTPUT_DIR}${/}order_results${order}[Order number].pdf     ${receiptsDir}
    # Go to order another robot
    Click Element When Visible  id:order-another
    # Close the annoying modal
    Wait Until Page Contains Element    class:modal-content
    Click Button    OK

Fill the form using the data from the Excel file
    ${orders}=    Read table from CSV    orders.csv
    Close Workbook
    FOR    ${order}    IN    @{orders}
        Fill and submit the form for one order    ${order}
    END
 
Create ZIP file of all receipts
    Archive Folder With Zip     ${receiptsDir}  ${OUTPUT_DIR}${/}receipts.zip

Close Down
    Remove Directory    Receipts   True
    [Teardown]  Close Browser

Minimal task
    Log    Done.
