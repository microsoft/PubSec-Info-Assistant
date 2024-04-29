// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import React, { useState, useEffect, useRef, useLayoutEffect } from "react";

import { DetailsList, 
    DetailsListLayoutMode, 
    SelectionMode, 
    IColumn, 
    Selection, 
    TooltipHost,
    Button,
    Dialog, 
    DialogType, 
    DialogFooter, 
    PrimaryButton,
    DefaultButton, 
    Panel,
    PanelType} from "@fluentui/react";
import styles from "./DocumentsDetailList.module.css";
import { deleteItem, DeleteItemRequest, resubmitItem, ResubmitItemRequest } from "../../api";
import { StatusContent } from "../StatusContent/StatusContent";
import { Delete24Regular,
    Send24Regular,
    ArrowClockwise24Regular,
    ImageBorderRegular,
    DocumentFolderFilled,
    ImageBorderFilled
    } from "@fluentui/react-icons";

export interface IDocument {
    key: string;
    name: string;
    value: string;
    iconName: string;
    fileType: string;
    filePath: string;
    fileFolder: string;
    state: string;
    state_description: string;
    upload_timestamp: string;
    modified_timestamp: string;
    status_updates: Array<{
        status: string;
        status_timestamp: string;
        status_classification: string;
    }>;
    isSelected?: boolean; // Optional property to track selection state
    tags: string;
}


interface Props {
    items: IDocument[];
    onFilesSorted?: (items: IDocument[]) => void;
    onRefresh: () => void; 
}

export const DocumentsDetailList = ({ items, onFilesSorted, onRefresh }: Props) => {
    const itemsRef = useRef(items);

    const onColumnClick = (ev: React.MouseEvent<HTMLElement>, column: IColumn): void => {
        const newColumns: IColumn[] = columns.slice();
        const currColumn: IColumn = newColumns.filter(currCol => column.key === currCol.key)[0];
        newColumns.forEach((newCol: IColumn) => {
            if (newCol === currColumn) {
                currColumn.isSortedDescending = !currColumn.isSortedDescending;
                currColumn.isSorted = true;
            } else {
                newCol.isSorted = false;
                newCol.isSortedDescending = true;
            }
        });
        const newItems = copyAndSort(items, currColumn.fieldName!, currColumn.isSortedDescending);
        items = newItems as IDocument[];
        setItems(newItems); 
        setColumns(newColumns);
        onFilesSorted == undefined ? console.log("onFileSorted event undefined") : onFilesSorted(items);
    };

    function copyAndSort<T>(items: T[], columnKey: string, isSortedDescending?: boolean): T[] {
        const key = columnKey as keyof T; // Cast columnKey to the type of the keys of T
        const sortedItems = items.slice().sort((a: T, b: T) => {
            if (columnKey === 'name') {
                const nameA = String(a[key]).toLowerCase();
                const nameB = String(b[key]).toLowerCase();
                return nameA < nameB ? -1 : nameA > nameB ? 1 : 0;
            } else {
                return a[key] < b[key] ? -1 : a[key] > b[key] ? 1 : 0;
            }
        });
        return isSortedDescending ? sortedItems.reverse() : sortedItems;
    }

    function getKey(item: any, index?: number): string {
        return item.key;
    }

    function onItemInvoked(item: any): void {
        alert(`Item invoked: ${item.name}`);
    }

    const [itemList, setItems] = useState<IDocument[]>(items);
    
    // Initialize Selection with items
    useEffect(() => {
        selectionRef.current.setItems(itemList, false);
    }, [itemList]);

    const selectionRef = useRef(new Selection({
        onSelectionChanged: () => {
            const selectedIndices = new Set(selectionRef.current.getSelectedIndices());
            setItems(prevItems => prevItems.map((item, index) => ({
                ...item,
                isSelected: selectedIndices.has(index)
            })));
        }
    }));
    

    // Notification of processing
    // Define a type for the props of Notification component
    interface NotificationProps {
        message: string;
    }

    const [notification, setNotification] = useState({ show: false, message: '' });

    const Notification = ({ message }: NotificationProps) => {
        // Ensure to return null when notification should not be shown
        if (!notification.show) return null;
    
        return <div className={styles.notification}>{message}</div>;
    };

    useEffect(() => {
        if (notification.show) {
            const timer = setTimeout(() => {
                setNotification({ show: false, message: '' });
            }, 3000); // Hides the notification after 3 seconds
            return () => clearTimeout(timer);
        }
    }, [notification]);

    // *************************************************************
    // Delete processing
    // New state for managing dialog visibility and selected items
    const [isDeleteDialogVisible, setIsDeleteDialogVisible] = useState(false);
    const [selectedItemsForDeletion, setSelectedItemsForDeletion] = useState<IDocument[]>([]);

    // Function to open the dialog with selected items
    const showDeleteConfirmation = () => {
        const selectedItems = selectionRef.current.getSelection() as IDocument[];
        setSelectedItemsForDeletion(selectedItems);
        setIsDeleteDialogVisible(true);
    };

    // Function to handle actual deletion
    const handleDelete = () => {
        setIsDeleteDialogVisible(false);
        console.log("Items to delete:", selectedItemsForDeletion);
        selectedItemsForDeletion.forEach(item => {
            console.log(`Deleting item: ${item.name}`);
            // delete this item
            const request: DeleteItemRequest = {
                path: item.filePath
            }
            const response = deleteItem(request);
        });
        // Notification after deletion
        setNotification({ show: true, message: 'Processing deletion. Hit \'Refresh\' to track progress' });
    };
    

    // Function to handle the delete button click
    const handleDeleteClick = () => {
        showDeleteConfirmation();
    };

    // *************************************************************
    // Resubmit processing
    // New state for managing resubmit dialog visibility and selected items
    const [isResubmitDialogVisible, setIsResubmitDialogVisible] = useState(false);
    const [selectedItemsForResubmit, setSelectedItemsForResubmit] = useState<IDocument[]>([]);

    // Function to open the resubmit dialog with selected items
    const showResubmitConfirmation = () => {
        const selectedItems = selectionRef.current.getSelection() as IDocument[];
        setSelectedItemsForResubmit(selectedItems);
        setIsResubmitDialogVisible(true);
    };

    // Function to handle actual resubmission
    const handleResubmit = () => {
        setIsResubmitDialogVisible(false);
        console.log("Items to resubmit:", selectedItemsForResubmit);
        selectedItemsForResubmit.forEach(item => {
            console.log(`Resubmitting item: ${item.name}`);
            // resubmit this item
            const request: ResubmitItemRequest = {
                path: item.filePath
            }
            const response = resubmitItem(request);
        });
        // Notification after resubmission
        setNotification({ show: true, message: 'Processing resubmit. Hit \'Refresh\' to track progress' });
    };
    
    // Function to handle the resubmit button click
    const handleResubmitClick = () => {
        showResubmitConfirmation();
    };

    // ********************************************************************
    // State detail dialog
    const [value, setValue] = useState('Initial value');
    const [stateDialogVisible, setStateDialogVisible] = useState(false);
    const [stateDialogContent, setStateDialogContent] = useState<React.ReactNode>(null);
    const scrollableContentRef = useRef<HTMLDivElement>(null);

    const refreshProp = (item: any) => {
        setValue(item);
      };

    const onStateColumnClick = (item: IDocument) => {
        try {
            refreshProp(item);
            setStateDialogVisible(true);
        } catch (error) {
            console.error("Error on state column click:", error);
            // Handle error here, perhaps show an error message to the user
        }
    };

    const dialogStyles = {
        main: {
            width: '400px',  // Set the width to 400 pixels
            maxWidth: '400px', // Set the maximum width to 400 pixels
            maxHeight: '400px', // Set the maximum height to 400 pixels
            overflowY: 'auto', // Enable vertical scrolling for the entire dialog if needed
        },
    };


    useEffect(() => {
        // Scroll to the top when the dialog opens
        window.scrollTo({ top: 0, left: 0, behavior: 'smooth' });
    }, []);

    const [columns, setColumns] = useState<IColumn[]> ([
        {
            key: 'file_type',
            name: 'File Type',
            className: styles.fileIconCell,
            iconClassName: styles.fileIconHeaderIcon,
            ariaLabel: 'Column operations for File type, Press to sort on File type',
            iconName: 'Page',
            isIconOnly: true,
            fieldName: 'name',
            minWidth: 16,
            maxWidth: 16,
            onColumnClick: onColumnClick,
            onRender: (item: IDocument) => {
                let src;
                const supportedFileTypes = ['XML', 'JSON', 'CSV', 'TSV', 'PPTX', 'DOCX', 'PDF', 'TXT', 'XLSX', 'HTM', 'HTML', 'EML', 'MSG'];
                if (item.fileType === 'PNG' || item.fileType === 'JPEG' || item.fileType === 'JPG') {
                    return (
                        <TooltipHost content={`${item.fileType} file`}>
                            <ImageBorderFilled className={styles.fileIconImg} aria-label={`${item.fileType} file icon`} fontSize="16px" />
                        </TooltipHost>
                    );   
                } else if (supportedFileTypes.includes(item.fileType)) {
                    src = `https://res-1.cdn.office.net/files/fabric-cdn-prod_20221209.001/assets/item-types/16/${item.iconName}.svg`;
                    return (
                        <TooltipHost content={`${item.fileType} file`}>
                            <img src={src} className={styles.fileIconImg} alt={`${item.fileType} file icon`} />
                        </TooltipHost>
                    );
                } else {
                    // The file type is not supported, return a default icon
                    return (
                        <TooltipHost content={`${item.fileType} file`}>
                            <DocumentFolderFilled className={styles.fileIconImg} aria-label={`${item.fileType} file icon`} fontSize="16px"/>
                        </TooltipHost>
                    );
                }
            }
        },
        {
            key: 'name',
            name: 'Name',
            fieldName: 'name',
            minWidth: 210,
            maxWidth: 350,
            isRowHeader: true,
            isResizable: true,
            sortAscendingAriaLabel: 'Sorted A to Z',
            sortDescendingAriaLabel: 'Sorted Z to A',
            onColumnClick: onColumnClick,
            data: 'string',
            isPadded: true,
        },
        {
            key: 'state',
            name: 'State',
            fieldName: 'state',
            minWidth: 70,
            maxWidth: 90,
            isResizable: true,
            ariaLabel: 'Column operations for state, Press to sort by states',
            onColumnClick: onColumnClick,
            data: 'string',
            onRender: (item: IDocument) => (
                <TooltipHost content={`${item.state} `}>
                    <span onClick={() => onStateColumnClick(item)} style={{ cursor: 'pointer' }}>
                        {item.state}
                    </span>
                </TooltipHost>
            ), 
            isPadded: true,
        },
        {
            key: 'fileFolder',
            name: 'Folder',
            fieldName: 'fileFolder',
            minWidth: 70,
            maxWidth: 90,
            isResizable: true,
            ariaLabel: 'Column operations for folder, Press to sort by folder',
            onColumnClick: onColumnClick,
            data: 'string',
        },
        {
            key: 'tags',
            name: 'Tags',
            fieldName: 'tags',
            minWidth: 70,
            maxWidth: 90,
            isResizable: true,
            sortAscendingAriaLabel: 'Sorted A to Z',
            sortDescendingAriaLabel: 'Sorted Z to A',
            onColumnClick: onColumnClick,
            data: 'string',
            isPadded: true,
        },
        {
            key: 'upload_timestamp',
            name: 'Submitted On',
            fieldName: 'upload_timestamp',
            minWidth: 90,
            maxWidth: 120,
            isResizable: true,
            isCollapsible: true,
            ariaLabel: 'Column operations for submitted on date, Press to sort by submitted date',
            data: 'string',
            onColumnClick: onColumnClick,
            onRender: (item: IDocument) => {
                return <span>{item.upload_timestamp}</span>;
            },
            isPadded: true,
        },
        {
            key: 'modified_timestamp',
            name: 'Last Updated',
            fieldName: 'modified_timestamp',
            minWidth: 90,
            maxWidth: 120,
            isResizable: true,
            isSorted: true,
            isSortedDescending: false,
            sortAscendingAriaLabel: 'Sorted Oldest to Newest',
            sortDescendingAriaLabel: 'Sorted Newest to Oldest',
            isCollapsible: true,
            ariaLabel: 'Column operations for last updated on date, Press to sort by last updated date',
            data: 'number',
            onColumnClick: onColumnClick,
            onRender: (item: IDocument) => {
                return <span>{item.modified_timestamp}</span>;
            },
        },
        {
            key: 'state_description',
            name: 'Status Detail',
            fieldName: 'state_description',
            minWidth: 90,
            maxWidth: 200,
            isResizable: true,
            isCollapsible: true,
            ariaLabel: 'Column operations for status detail',
            data: 'string',
            onColumnClick: onColumnClick,
            onRender: (item: IDocument) => (
                <TooltipHost content={`${item.state_description} `}>
                    <span onClick={() => onStateColumnClick(item)} style={{ cursor: 'pointer' }}>
                        {item.state_description}
                    </span>
                </TooltipHost>
            )
        }
    ]);

    return (
        <div>
            <div className={styles.buttonsContainer}>
                <div className={`${styles.refresharea} ${styles.divSpacing}`} onClick={onRefresh} aria-label=" Refresh">
                    <ArrowClockwise24Regular className={styles.refreshicon} />
                    <span className={`${styles.refreshtext} ${styles.centeredText}`}>Refresh</span>
                </div>        
                <div className={`${styles.refresharea} ${styles.divSpacing}`} onClick={handleDeleteClick} aria-label=" Delete">
                    <Delete24Regular className={styles.refreshicon} />
                    <span className={`${styles.refreshtext} ${styles.centeredText}`}>Delete</span>
                </div>
                <div className={`${styles.refresharea} ${styles.divSpacing}`} onClick={handleResubmitClick} aria-label=" Resubmit">
                    <Send24Regular className={styles.refreshicon} />
                    <span className={`${styles.refreshtext} ${styles.centeredText}`}>Resubmit</span>
                </div>
            </div>
            <span className={styles.footer}>{"(" + items.length as string + ") records."}</span>
            <DetailsList
                items={itemList}
                compact={true}
                columns={columns}
                selection={selectionRef.current}
                selectionMode={SelectionMode.multiple} // Allow multiple selection
                getKey={getKey}
                setKey="none"
                layoutMode={DetailsListLayoutMode.justified}
                isHeaderVisible={true}
                onItemInvoked={onItemInvoked}
            />
            <span className={styles.footer}>{"(" + items.length as string + ") records."}</span>
            {/* <Button text="Delete" onClick={handleDeleteClick} style={{ marginRight: '10px' }} />
            <Button text="Resubmit" onClick={handleResubmitClick} /> */}
            {/* Dialog for delete confirmation */}
            <Dialog
                hidden={!isDeleteDialogVisible}
                onDismiss={() => setIsDeleteDialogVisible(false)}
                dialogContentProps={{
                    type: DialogType.normal,
                    title: 'Delete Confirmation',
                    subText: 'Are you sure you want to delete the selected items?'
                }}
                modalProps={{
                    isBlocking: true,
                    styles: { main: { maxWidth: 450 } }
                }}
            >
                <DialogFooter>
                    <PrimaryButton onClick={handleDelete} text="Delete" />
                    <DefaultButton onClick={() => setIsDeleteDialogVisible(false)} text="Cancel" />
                </DialogFooter>
            </Dialog>
            {/* Dialog for resubmit confirmation */}
            <Dialog
                hidden={!isResubmitDialogVisible}
                onDismiss={() => setIsResubmitDialogVisible(false)}
                dialogContentProps={{
                    type: DialogType.normal,
                    title: 'Resubmit Confirmation',
                    subText: 'Are you sure you want to resubmit the selected items?'
                }}
                modalProps={{
                    isBlocking: true,
                    styles: { main: { maxWidth: 450 } }
                }}
            >
                <DialogFooter>
                    <PrimaryButton onClick={handleResubmit} text="Resubmit" />
                    <DefaultButton onClick={() => setIsResubmitDialogVisible(false)} text="Cancel" />
                </DialogFooter>
            </Dialog>
            <div>
                <Notification message={notification.message} />
            </div>            
                <Panel
                    headerText="Status Log"
                    isOpen={stateDialogVisible}
                    isBlocking={false}
                    onDismiss={() => setStateDialogVisible(false)}
                    closeButtonAriaLabel="Close"
                    onRenderFooterContent={() => <DefaultButton onClick={() => setStateDialogVisible(false)}>Close</DefaultButton>}
                    isFooterAtBottom={true}
                    type={PanelType.medium}
                >
                    <div className={styles.resultspanel}>
                    <StatusContent item={value} />
                    </div>
                </Panel>
        </div>
    );
}
