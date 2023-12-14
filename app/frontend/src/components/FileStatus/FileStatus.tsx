// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import { useState } from "react";
import { Dropdown, DropdownMenuItemType, IDropdownOption, IDropdownStyles } from '@fluentui/react/lib/Dropdown';
import { Stack } from "@fluentui/react";
import { DocumentsDetailList, IDocument } from "./DocumentsDetailList";
import { ArrowClockwise24Filled } from "@fluentui/react-icons";
import { animated, useSpring } from "@react-spring/web";
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
    { key: FileState.Indexing, text: 'Indexing' },
    { key: FileState.Queued, text: 'Queued' },
    { key: FileState.Skipped, text: 'Skipped'},
    { key: FileState.UPLOADED, text: 'Uploaded'},
    { key: FileState.THROTTLED, text: 'Throttled'},    
  ];

interface Props {
    className?: string;
}

export const FileStatus = ({ className }: Props) => {
    const [selectedTimeFrameItem, setSelectedTimeFrameItem] = useState<IDropdownOption>();
    const [selectedFileStateItem, setSelectedFileStateItem] = useState<IDropdownOption>();
    const [files, setFiles] = useState<IDocument[]>();
    const [isLoading, setIsLoading] = useState<boolean>(false);

    const onTimeSpanChange = (event: React.FormEvent<HTMLDivElement>, item: IDropdownOption<any> | undefined): void => {
        setSelectedTimeFrameItem(item);
    };

    const onFileStateChange = (event: React.FormEvent<HTMLDivElement>, item: IDropdownOption<any> | undefined): void => {
        setSelectedFileStateItem(item);
    };

    const onFilesSorted = (items: IDocument[]): void => {
        setFiles(items);
    };

    const onGetStatusClick = async () => {
        setIsLoading(true);
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
                timeframe = 168;
                break;
            case "30days":
                timeframe = 720;
                break;
            default:
                timeframe = 4;
                break;
        }

        const request: GetUploadStatusRequest = {
            timeframe: timeframe,
            state: selectedFileStateItem?.key == undefined ? FileState.All : selectedFileStateItem?.key as FileState
        }
        const response = await getAllUploadStatus(request);
        const list = convertStatusToItems(response.statuses);
        setIsLoading(false);
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

    const animatedStyles = useSpring({
        from: { opacity: 0 },
        to: { opacity: 1 }
    });

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
                    aria-label="timespan options for file statuses to be displayed"
                />
            <Dropdown
                    label="File State:"
                    defaultSelectedKey={'ALL'}
                    onChange={onFileStateChange}
                    placeholder="Select file states"
                    options={dropdownFileStateOptions}
                    styles={dropdownFileStateStyles}
                    aria-label="file state options for file statuses to be displayed"
                />
            <div className={styles.refresharea} onClick={onGetStatusClick} aria-label="Refresh displayed file statuses">
                <ArrowClockwise24Filled className={styles.refreshicon} />
                <span className={styles.refreshtext}>Refresh</span>
            </div>
            </div>
            {isLoading ? (
                <animated.div style={{ ...animatedStyles }}>
                     <Stack className={styles.loadingContainer} verticalAlign="space-between">
                        <Stack.Item grow>
                            <p className={styles.loadingText}>
                                Getting file statuses
                                <span className={styles.loadingdots} />
                            </p>
                        </Stack.Item>
                    </Stack>
                </animated.div>
            ) : (
                <div className={styles.resultspanel}>
                    <DocumentsDetailList items={files == undefined ? [] : files} onFilesSorted={onFilesSorted}/>
                </div>
            )}
        </div>
    );
};