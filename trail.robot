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


*** Variables ***
${folder path}=     C:/Users/kamma.naveen/Documents/RoboCorp/Project tracker/input


*** Tasks ***
Minimal task
    ${row}=    Set Variable    2
    Open Workbook
    ...    C:/Users/kamma.naveen/Documents/RoboCorp/Project tracker/input/Report - 2023-02-13T095706.212.xls
    Create Worksheet    NEW op
    Save Workbook
    Sleep    2s
    ${OP}=    For Each Input Work Item    Load workitem

    #WRITE DATA TO NEW SHEET    ${row}    ${OP}

    # Log    ${row}


*** Keywords ***
Load workitem
    ${payload}=    Get Work Item Variables
    RETURN    ${payload}

counter
    [Arguments]    ${row}
    ${COUNT}=    Evaluate    ${row}+1
    RETURN    ${COUNT}
    Log    ${COUNT}

WRITE DATA TO NEW SHEET
    [Arguments]    ${op}    ${payload}
    FOR    ${i}    IN    @${op}[0]
        Log    ${i}
        ${Name}=    Set Variable    ${i}[Name]
        ${Key Skill}=    Set Variable    ${i}[Key Skill]
        ${Client}=    Set Variable    ${i}[Client]
        ${Start Date}=    Set Variable    ${i}[Start Date]
        ${Designation}=    Set Variable    ${i}[Designation]
        ${Grade}=    Set Variable    ${i}[Grade]
        ${Primary Skill}=    Set Variable    ${i}[Primary Skill]
        ${Secondary Skill}=    Set Variable    ${i}[Secondary Skill]

        Open Workbook
        ...    C:/Users/kamma.naveen/Documents/RoboCorp/Project tracker/input/Report - 2023-02-13T095706.212.xls
        Set Active Worksheet    NEW op
        Set Worksheet Value    1    1    Name
        Set Worksheet Value    1    2    Key Skill
        Set Worksheet Value    1    3    Client
        Set Worksheet Value    1    4    Start Date
        Set Worksheet Value    1    5    Designation
        Set Worksheet Value    1    6    Grade
        Set Worksheet Value    1    7    Primary Skill
        Set Worksheet Value    1    8    Secondary Skill
        Set cell Value    ${op}[1]    1    ${Name}
        Set cell Value    ${payload}[1]    2    ${Key Skill}
        Set cell Value    ${payload}[1]    3    ${Client}
        Set cell Value    ${payload}[1]    4    ${Start Date}
        Set cell Value    ${payload}[1]    5    ${Designation}
        Set cell Value    ${payload}[1]    6    ${Grade}
        Set cell Value    ${payload}[1]    7    ${Primary Skill}
        Set cell Value    ${payload}[1]    8    ${Secondary Skill}
        Save Workbook
        Close Workbook
    END
