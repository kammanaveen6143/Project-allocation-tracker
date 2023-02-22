*** Settings ***
Documentation       Template robot main suite.

Library             RPA.Excel.Files
Library             RPA.Tables
Library             Collections
Library             RPA.FileSystem
Library             RPA.Outlook.Application
Library             RPA.JSON
Library             RPA.Robocorp.WorkItems
Library             RPA.Robocorp.Process
Library             RPA.Dialogs
Library             DateTime
Library             String


*** Variables ***
#please provide mail id in local machine
${localmail}=       kamma.naveen@yash.com


*** Tasks ***
Minimal task
    ${Dconfig}=    load config file
    check mailbox and download attached excel    ${Dconfig}
    ${input}=    Read input excel    ${Dconfig}
    ${colerror}=    filter table using required columns and save in csv    ${Dconfig}    ${input}
    ${OPtable}=    get count of allocations and send mail to costumer    ${input}    ${Dconfig}    ${colerror}


*** Keywords ***
load config file
    TRY
        ${config}=    Load JSON from file    Config.json
    EXCEPT
        ${config}=    Set Variable    fail
    END
    IF    "${config}" == "fail"
        Open Application
        Send Email    ${localmail}    Bot failure    Config file is missing
        ${configstatus}=    Set Variable    fail
    ELSE
        TRY
            ${mailid}=    Set Variable    ${config}[user mail]
            ${subject}=    Set Variable    ${config}[Subject]
            ${filename}=    Set Variable    ${config}[filename]
            ${costumerid}=    Set Variable    ${config}[costumor mail]
            ${Name}=    Set Variable    ${config}[Column1]
            ${Key Skill}=    Set Variable    ${config}[Column2]
            ${Client}=    Set Variable    ${config}[Column3]
            ${Start Date}=    Set Variable    ${config}[Column4]
            ${Designation}=    Set Variable    ${config}[Column5]
            ${Grade}=    Set Variable    ${config}[Column6]
            ${Primary Skill}=    Set Variable    ${config}[Column7]
            ${Secondary Skill}=    Set Variable    ${config}[Column8]
            ${to}=    Set Variable    ${config}[to]
            ${from}=    Set Variable    ${config}[from]
            ${configstatus}=    Set Variable    sucess
        EXCEPT
            ${configstatus}=    Set Variable    fail
        END
        IF    "${configstatus}" == "fail"
            ${Dconfig}=    Set Variable    fail
        ELSE
            ${Dconfig}=    Create Dictionary
            ...    user mail=${mailid}
            ...    Subject=${subject}
            ...    filename=${filename}
            ...    costumor mail=${costumerid}
            ...    Name=${Name}
            ...    Key Skill=${Key Skill}
            ...    Client=${Client}
            ...    Start Date=${Start Date}
            ...    Designation=${Designation}
            ...    Grade=${Grade}
            ...    Primary Skill=${Primary Skill}
            ...    Secondary Skill=${Secondary Skill}
            ...    to=${to}
            ...    from=${from}
        END
    END
    RETURN    ${Dconfig}

check mailbox and download attached excel
    [Arguments]    ${Dconfig}
    Create Directory    input
    Create Directory    processed
    Create Directory    Output
    IF    "${Dconfig}" == "fail"
        Open Application
        Send Email    ${localmail}    Bot failure    Config data is missing please check the config file
    ELSE
        TRY
            Open Application
            Get Emails    account_name=${Dconfig}[costumor mail]
            ...    folder_name=Inbox
            ...    save_attachments=True
            ...    sort=True
            ...    email_filter=[Subject]= ${Dconfig}[Subject]
            ...    attachment_folder=input
            Sleep    2s
        EXCEPT
            Open Application
            Send Email    kamma.naveen@yash.com    Bot failure    No mails arrived
            Log    error
        END
    END

Read input excel
    [Arguments]    ${Dconfig}

    ${folder}=    List Files In Directory    input
    ${length}=    Get Length    ${folder}
    IF    ${length} == 0
        Log    mail not found
        ${input}=    Set Variable    fail
    ELSE
        ${name}=    Get File Name    ${folder}[0]
        Log    ${name}
        IF    "${Dconfig}[filename]" in "${name}"
            Open Workbook    input/${name}
            Set Active Worksheet    REPORT_SHEET
            ${input}=    Read Worksheet As Table    header=True    start=${2}
        ELSE
            ${input}=    Set Variable    missing
        END
        ${num}=    List Files In Directory    processed
        ${length}=    Get Length    ${num}
        ${len}=    Evaluate    ${length}+1
        Move File    input/${name}    processed/${name}-${len}
        Empty Directory    input
    END
    RETURN    ${input}

filter table using required columns and save in csv
    [Arguments]    ${Dconfig}    ${input}
    IF    "${input}" == "fail"
        Open Application
        Send Email
        ...    ${localmail}
        ...    Bot failure
        ...    mail not found pls send the attachment with Allocation tracker as subject
        ${colerror}=    Set Variable    mail
    ELSE IF    "${input}" == "missing"
        Open Application
        Send Email
        ...    ${localmail}
        ...    Bot failure
        ...    attachment    not found pls send the attachment with Allocation tracker as subject
        ${colerror}=    Set Variable    file
    ELSE
        TRY
            ${Name}=    Get Table Column    ${input}    ${Dconfig}[Name]
            ${Key Skill}=    Get Table Column    ${input}    ${Dconfig}[Key Skill]
            ${Client}=    Get Table Column    ${input}    ${Dconfig}[Client]
            ${Start Date}=    Get Table Column    ${input}    ${Dconfig}[Start Date]
            ${Designation}=    Get Table Column    ${input}    ${Dconfig}[Designation]
            ${Grade}=    Get Table Column    ${input}    ${Dconfig}[Grade]
            ${Primary Skill}=    Get Table Column    ${input}    ${Dconfig}[Primary Skill]
            ${Secondary Skill}=    Get Table Column    ${input}    ${Dconfig}[Secondary Skill]
            ${new table}=    Create Dictionary
            ...    Name=${Name}
            ...    Key Skill=${Key Skill}
            ...    Client=${Client}
            ...    Start Date=${Start Date}
            ...    Designation=${Designation}
            ...    Grade=${Grade}
            ...    Primary Skill=${Primary Skill}
            ...    Secondary Skill=${Secondary Skill}
            ${finaltable}=    Create Table    ${new table}
            Sort Table By Column    ${finaltable}    Client
            Write table to CSV    ${finaltable}    output/Employes data.CSV
            ${colerror}=    Set Variable    done
        EXCEPT
            ${colerror}=    Set Variable    fail
        END
    END
    RETURN    ${colerror}

get count of allocations and send mail to costumer
    [Arguments]    ${input}    ${Dconfig}    ${colerror}
    IF    "${colerror}" == "fail"
        Open Application
        Send Email    ${Dconfig}[costumor mail]    Bot failure    Required columns are not available in given excel
    ELSE IF    "${colerror}" == "mail"
        Log    mail not found
    ELSE IF    "${colerror}" == "file"
        Log    file not found
    ELSE
        ${BFTE}=    Find Table Rows    ${input}    Allocation    contains    Billable (Full Time (FTE))
        ${Bpartial}=    Find Table Rows    ${input}    Allocation    contains    Billable (Partial)
        ${NBCOA}=    Find Table Rows    ${input}    Allocation    contains    Non-Billable (Client On-boarding Awaited)
        ${NBDM}=    Find Table Rows    ${input}    Allocation    contains    Non-Billable (Delivery Management)
        ${NBinv}=    Find Table Rows    ${input}    Allocation    contains    Non-Billable (Investment)
        ${NBT}=    Find Table Rows    ${input}    Allocation    contains    Non-Billable (Trainee)
        ${NBU}=    Find Table Rows    ${input}    Allocation    contains    Non-Billable (Unallocated)
        ${NBSH}=    Find Table Rows    ${input}    Allocation    contains    Non-Billable Trainee (Shadow)
        ${BFTE}=    Get Length    ${BFTE}
        ${Bpartial}=    Get Length    ${Bpartial}
        ${NBCOA}=    Get Length    ${NBCOA}
        ${NBDM}=    Get Length    ${NBDM}
        ${NBinv}=    Get Length    ${NBinv}
        ${NBT}=    Get Length    ${NBT}
        ${NBU}=    Get Length    ${NBU}
        ${NBSH}=    Get Length    ${NBSH}
        ${Total}=    Evaluate    ${BFTE}+${Bpartial}+${NBCOA}+${NBDM}+${NBinv}+${NBT}+${NBU}+${NBSH}
        Log    ${Total}

        TRY
            Open Application
            Send Email
            ...    ${Dconfig}[costumor mail]
            ...    Bot report
            ...    body=<p>Hi ${Dconfig}[to],</p><p>Bot runs sucessfully, Please find the attachment for employee details and below are the allocation detailes</p><table border="1" cellpadding="1" cellspacing="1" style="width:500px;"><tbody><tr><td>Allocation</td><td>Total</td></tr><tr><td>Billable (Full Time (FTE))</td><td>${BFTE}</td></tr><tr><td>Billable (Partial)</td><td>${Bpartial}</td></tr><tr><td>Non-Billable (Client On-boarding Awaited)</td><td>${NBCOA}</td></tr><tr><td>Non-Billable (Delivery Management</td><td>${NBDM}</td></tr><tr><td>Non-Billable (Investment)</td><td>${NBinv}</td></tr><tr><td>Non-Billable (Trainee)</td><td>${NBT}</td></tr><tr><td>Non-Billable (Unallocated)</td><td>${NBU}</td></tr><tr><td>Non-Billable Trainee (Shadow)</td><td>${NBSH}</td></tr><tr><td>Total</td><td>${Total}</td></tr></tbody></table><p>&nbsp;</p> <p>Thanks & Regards<br>${Dconfig}[from]</p><br>
            ...    html_body=${True}
            ...    attachments=output/Employes data.CSV
        EXCEPT
            Open Application
            Send Email    ${Dconfig}[user mail]    Bot failure    Unable to send the mail to costumer
        END
    END
