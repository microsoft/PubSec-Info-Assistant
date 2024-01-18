// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import { useState } from "react";
import { DetailsList, DetailsListLayoutMode, SelectionMode, IColumn, Selection, Label, Text, BaseSelectedItemsList } from "@fluentui/react";
import { TooltipHost } from '@fluentui/react';
import { retryFile } from "../../api";
import React, { useRef } from "react";

import styles from "./DocumentsDetailList.module.css";

export interface IDocument {
    key: string;
    name: string;
    value: string;
    iconName: string;
    fileType: string;
    filePath: string;
    state: string;
    state_description: string;
    upload_timestamp: string;
    modified_timestamp: string;
}

interface Props {
    items: IDocument[];
    onFilesSorted?: (items: IDocument[]) => void;
}

export const DocumentsDetailList = ({ items, onFilesSorted}: Props) => {
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
        setColumns(newColumns);
        onFilesSorted == undefined ? console.log("onFileSorted event undefined") : onFilesSorted(items);
    };

    function copyAndSort<T>(items: T[], columnKey: string, isSortedDescending?: boolean): T[] {
        const key = columnKey as keyof T;
        return items.slice(0).sort((a: T, b: T) => ((isSortedDescending ? a[key] < b[key] : a[key] > b[key]) ? 1 : -1));
    }

    function getKey(item: any, index?: number): string {
        return item.key;
    }

    function onItemInvoked(item: any): void {
        alert(`Item invoked: ${item.name}`);
    }

    const [itemList, setItems] = useState<IDocument[]>(items);
    function retryErroredFile(item: IDocument): void {
        retryFile(item.filePath)
            .then(() => {
                // Create a new array with the updated item
                const updatedItems = itemList.map((i) => {
                    if (i.key === item.key) {
                        return {
                            ...i,
                            state: "Queued"
                        };
                    }
                    return i;
                });
    
                setItems(updatedItems); // Update the state with the new array
                console.log("State updated, triggering re-render");
            })
            .catch((error) => {
                console.error("Error retrying file:", error);
            });
    }


    const [columns, setColumns] = useState<IColumn[]> ([
        {
            key: 'column1',
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
            onRender: (item: IDocument) => (
                <TooltipHost content={`${item.fileType} file`}>
                    <img src={"https://res-1.cdn.office.net/files/fabric-cdn-prod_20221209.001/assets/item-types/16/" + item.iconName + ".svg"} className={styles.fileIconImg} alt={`${item.fileType} file icon`} />
                </TooltipHost>
            ),
        },
        {
            key: 'column2',
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
            key: 'column3',
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
                    <span>{item.state}</span>  
                    {item.state === 'Error' && <a href="javascript:void(0);" onClick={() => retryErroredFile(item)}> Retry File</a>}  
                </TooltipHost>  
            ), 
            isPadded: true,
        },
        {
            key: 'column4',
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
            key: 'column5',
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
            key: 'column6',
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
                    <span>{item.state}</span>
                </TooltipHost>
            ),
        }
    ]);

    return (
        <div>
            <span className={styles.footer}>{"(" + items.length as string + ") records."}</span>
            <DetailsList
                // items={items}
                items={itemList}
                compact={true}
                columns={columns}
                selectionMode={SelectionMode.none}
                getKey={getKey}
                setKey="none"
                layoutMode={DetailsListLayoutMode.justified}
                isHeaderVisible={true}
                onItemInvoked={onItemInvoked}
            />
            <span className={styles.footer}>{"(" + items.length as string + ") records."}</span>
        </div>
    );
}