// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import { useState } from "react";
import { Dropdown, DropdownMenuItemType, IDropdownOption, IDropdownStyles } from '@fluentui/react/lib/Dropdown';
import { DocumentsDetailList, IDocument } from "./DocumentsDetailList";
import { ArrowClockwise24Filled } from "@fluentui/react-icons";
import { getAllUploadStatus, FileUploadBasicStatus, GetUploadStatusRequest, FileState } from "../../api";

import styles from "./FileStatus.module.css";

const dropdownTimespanStyles: Partial<IDropdownStyles> = { dropdown: { width: 150 } };
const dropdownFileStateStyles: Partial<IDropdownStyles> = { dropdown: { width: 200 } };

const dropdownTimespanOptions = [
    { key: 'Time Range', text: 'End time range', itemType: DropdownMenuItemType.Header },
    { key: '4hours', text: '4 hours' },
    { key: '12hours', text: '12 hours' },
    { key: '24hours', text: '24 hours' },
    { key: '7days', text: '7 days' },
    { key: '30days', text: '30 days' },
  ];

const dropdownFileStateOptions = [
    { key: 'FileStates', text: 'File States', itemType: DropdownMenuItemType.Header },
    { key: FileState.All, text: 'All' },
    { key: FileState.Complete, text: 'Completed' },
    { key: FileState.Error, text: 'Error' },
    { key: FileState.Processing, text: 'Processing' },
    { key: FileState.Queued, text: 'Queued' },
    { key: FileState.Skipped, text: 'Skipped'},
  ];

interface Props {
    className?: string;
}

export const FileStatus = ({ className }: Props) => {
    const [selectedTimeFrameItem, setSelectedTimeFrameItem] = useState<IDropdownOption>();
    const [selectedFileStateItem, setSelectedFileStateItem] = useState<IDropdownOption>();
    const [files, setFiles] = useState<IDocument[]>();

    const onTimeSpanChange = (event: React.FormEvent<HTMLDivElement>, item: IDropdownOption<any> | undefined): void => {
        setSelectedTimeFrameItem(item);
    };

    const onFileStateChange = (event: React.FormEvent<HTMLDivElement>, item: IDropdownOption<any> | undefined): void => {
        setSelectedFileStateItem(item);
    };

    const onGetStatusClick = async () => {
        var timeframe = 4;
        switch (selectedTimeFrameItem?.key as string) {
            case "4hours":
                timeframe = 4;
                break;
            case "12hours":
                timeframe = 12;
                break;
            case "24hours":
                timeframe = 24;
                break;
            case "7days":
                timeframe = 10080;
                break;
            case "30days":
                timeframe = 43200;
                break;
            default:
                timeframe = -4;
                break;
        }

        const request: GetUploadStatusRequest = {
            timeframe: timeframe,
            state: selectedFileStateItem?.key == undefined ? FileState.All : selectedFileStateItem?.key as FileState
        }
        const response = await getAllUploadStatus(request);
        const list = convertStatusToItems(response.statuses);
        setFiles(list);
    }

    function convertStatusToItems(fileList: FileUploadBasicStatus[]) {
        const items: IDocument[] = [];
        for (let i = 0; i < fileList.length; i++) {
            let fileExtension = fileList[i].file_name.split('.').pop();
            fileExtension = fileExtension == undefined ? 'Folder' : fileExtension.toUpperCase()
            try {
                items.push({
                    key: fileList[i].id,
                    name: fileList[i].file_name,
                    iconName: FILE_ICONS[fileExtension.toLowerCase()],
                    fileType: fileExtension,
                    state: fileList[i].state,
                    state_description: fileList[i].state_description,
                    upload_timestamp: fileList[i].start_timestamp,
                    modified_timestamp: fileList[i].state_timestamp,
                    value: fileList[i].id,
                });
            }
            catch (e) {
                console.log(e);
            }
        }
        return items;
    }

    const FILE_ICONS: { [id: string]: string } = {
        "csv": 'csv',
        "docx": 'docx',
        "pdf": 'pdf',
        "pptx": 'pptx',
        "txt": 'txt',
        "html": 'xsn'
    };

    return (
        <div className={styles.container}>
            <div className={`${styles.options} ${className ?? ""}`} >
            <Dropdown
                    label="Uploaded in last:"
                    defaultSelectedKey='4hours'
                    onChange={onTimeSpanChange}
                    placeholder="Select a time range"
                    options={dropdownTimespanOptions}
                    styles={dropdownTimespanStyles}
                />
            <Dropdown
                    label="File State:"
                    defaultSelectedKey={'ALL'}
                    onChange={onFileStateChange}
                    placeholder="Select file states"
                    options={dropdownFileStateOptions}
                    styles={dropdownFileStateStyles}
                />
            <div className={styles.refresharea} onClick={onGetStatusClick}>
                <ArrowClockwise24Filled className={styles.refreshicon} />
                <span className={styles.refreshtext}>Refresh</span>
            </div>
            </div>
            <div className={styles.resultspanel}>
                <DocumentsDetailList items={files == undefined ? [] : files}/>
            </div>
        </div>
    );
};