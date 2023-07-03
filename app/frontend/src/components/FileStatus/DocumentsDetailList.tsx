// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import { useState } from "react";
import { DetailsList, DetailsListLayoutMode, SelectionMode, IColumn, Selection, Label } from "@fluentui/react";
import { TooltipHost } from '@fluentui/react';

import styles from "./DocumentsDetailList.module.css";

export interface IDocument {
    key: string;
    name: string;
    value: string;
    iconName: string;
    fileType: string;
    state: string;
    state_description: string;
    upload_timestamp: string;
    modified_timestamp: string;
}

interface Props {
    items: IDocument[];
}

export const DocumentsDetailList = ({ items}: Props) => {
    const [selectionDetails, setSelectionDetails] = useState<string>("");
    const selection = new Selection({
            onSelectionChanged: () => {
            setSelectionDetails(getSelectionDetails())}
          });

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

    function getSelectionDetails(): string {
        const selectionCount = selection?.getSelectedCount();

        switch (selectionCount) {
            case 0:
                return 'No items selected';
            case 1:
                return '1 item selected: ' + (selection?.getSelection()[0] as IDocument).name;
            default:
                return `${selectionCount} items selected`;
        }
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
            isSorted: true,
            isSortedDescending: false,
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
            onColumnClick: onColumnClick,
            data: 'string',
            onRender: (item: IDocument) => (
                <TooltipHost content={`${item.state_description} `}>
                    <span>{item.state}</span>
                </TooltipHost>
            ),
            isPadded: true,
        },
        {
            key: 'column4',
            name: 'Submitted On',
            fieldName: 'submittedOn',
            minWidth: 70,
            maxWidth: 90,
            isResizable: true,
            isCollapsible: true,
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
            fieldName: 'lastUpdated',
            minWidth: 70,
            maxWidth: 90,
            isResizable: true,
            isCollapsible: true,
            data: 'number',
            onColumnClick: onColumnClick,
            onRender: (item: IDocument) => {
                return <span>{item.modified_timestamp}</span>;
            },
        },
    ]);

    return (
        <div>
            <div className={styles.selectionDetails}>{selectionDetails}</div>
            <DetailsList
                items={items}
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