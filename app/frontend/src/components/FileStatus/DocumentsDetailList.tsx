// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import React, { useState, useEffect, useRef } from "react";
import StatusMessage from "../StatusMessage/StatusMessage";
import { AgGridReact } from "ag-grid-react";
//  import { LiveAnnouncer, LiveMessage } from 'react-aria-live';
import { AriaLiveAnnouncer, useAnnounce, Button} from "@fluentui/react-components";

import {
    Column
  } from "ag-grid-community";



import { DetailsList, 
    DetailsListLayoutMode, 
    SelectionMode, 
    IColumn, 
    Selection, 
    TooltipHost,
    Dialog, 
    DialogType, 
    DialogFooter, 
    PrimaryButton,
    DefaultButton, 
    Panel,
    PanelType,
    IDetailsCheckboxProps,
    IDetailsListCheckboxProps,
    IRenderFunction,
    Checkbox,
    ContextualMenu, IContextualMenuProps, Link,  TextField, ITextFieldStyles, ITextField, mergeStyles, getDocument, getTheme, buildColumns} from "@fluentui/react";
import styles from "./DocumentsDetailList.module.css";
import { IFocusZone, IDetailsList, IDragDropEvents, IDragDropContext, IColumnReorderOptions, ColumnActionsMode } from "@fluentui/react";
import { deleteItem, DeleteItemRequest, resubmitItem, ResubmitItemRequest } from "../../api";
import { StatusContent } from "../StatusContent/StatusContent";
import { Delete24Regular,
    ArrowClockwise24Regular,
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
    const [contextMenuVisible, setContextMenuVisible] = useState(false);
    const [selectedColumnIndex, setSelectedColumnIndex] = useState<number | null>(null);
    const [columnApi, setColumnApi] = useState<Column | null>(null);
  const [visible, setVisible] = useState(false);

    

const [selectedColumnId, setSelectedColumnId] = useState<string | null>(null);
const [currentColumnWidth, setCurrentColumnWidth] = useState<number>(100);
const [maxColumnWidth, setMaxColumnWidth] = useState<number>(500);

const onColumnClick = (ev: React.MouseEvent<HTMLElement>, column: IColumn): void => {
        
    setContextualMenuProps(getContextualMenuProps(ev, column));
};
const { announce } = useAnnounce()
const theme = getTheme();
const RESIZE = 'Resize';
const REORDER = 'Reorder';
const dragEnterClass = mergeStyles({
    backgroundColor: theme.palette.neutralLight,
  });
const handleWidthChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const newWidth = Number(e.target.value);
    setCurrentColumnWidth(newWidth);
    console.log('New width:', newWidth);
    console.log('Selected column:', selectedColumnId);
    if (selectedColumnId) {
        const newColumns = columns.map((col) => {
            if (col.key === selectedColumnId) {
                console.log('Setting new width for column:', col.key);
                onColumnResize(col, newWidth, columns.indexOf(col));
            }
        });
    }
};

const selectionRef = useRef(new Selection({
    onSelectionChanged: () => {
        const selectedIndices = new Set(selectionRef.current.getSelectedIndices());
        setItems(prevItems => prevItems.map((item, index) => ({
            ...item,
            isSelected: selectedIndices.has(index)
        })));
    }
}));

    const [status, setStatus] = useState('');
    const [message, setLiveMessage] = useState('');

    const gridRef = useRef<AgGridReact>(null);
    
    const [currentColId, setCurrentColId] = useState<string | null>(null);

    
    const onRenderCheckbox: IRenderFunction<IDetailsListCheckboxProps> = (props) => {
        // const item = props?.item;
        // const label = item ? getCheckButtonAriaLabel(item) : 'Select item';
     
        return (
            <Checkbox
                inputProps={{ tabIndex: 0 }}
                checked={props?.checked}
                aria-checked={props?.checked}
                // onChange={props?.onChange}
                // inputProps={{ role: 'checkbox', tabIndex: 0 }}
            />
        );
    };
    const getCheckButtonAriaLabel = (item: any): string => {
        return `Select item with key ${item.key}`;
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
    
    const onSelectionChanged = (event: any) => {
        const selectedRows = event.api.getSelectedRows();
        selectionRef.current = selectedRows;
      };
      
      useEffect(() => {
        console.log(selectionRef.current);  // You can log or use the selectionRef.current as needed
      }, [selectionRef.current]);
    

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
        const selectedItems = selectionRef.current as unknown as IDocument[];
        setSelectedItemsForDeletion(selectedItems);
        setIsDeleteDialogVisible(true);
    };

    // Function to handle actual deletion
    const DoDeletion = () => {
        handleDelete();
        announce("Selected item deletion process started. Hit Refresh button to track progress");
    }
    ;
    const handleDelete = () => {
        setIsDeleteDialogVisible(false);
        console.log("Items to delete:", selectedItemsForDeletion);
        
        console.log('live message:' ,message);
        selectedItemsForDeletion.forEach(item => {
            console.log(`Deleting item: ${item.name}`);
            const fullPath = `${item.filePath}/${item.name}`;
            // delete this item
            const request: DeleteItemRequest = {
                path: fullPath
            }
            const response = deleteItem(request);
        })
        // Notification after deletion
        setNotification({ show: true, message: 'Processing deletion. Hit \'Refresh\' to track progress' });
        setStatus('Processing deletion. Hit \'Refresh\' to track progress' );
        
        console.log(message);
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
        const selectedItems = selectionRef.current as unknown as IDocument[];
        setSelectedItemsForResubmit(selectedItems);
        setIsResubmitDialogVisible(true);
    };

    // Function to handle actual resubmission
    const handleResubmit = () => {
        setIsResubmitDialogVisible(false);
        console.log("Items to resubmit:", selectedItemsForResubmit);
        selectedItemsForResubmit.forEach(item => {
            console.log(`Resubmitting item: ${item.name}`);
            const fullPath = `${item.filePath}/${item.name}`;
            // resubmit this item
            const request: ResubmitItemRequest = {
                path: fullPath
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
    const [focusedColumnIndex, setFocusedColumnIndex] = useState<number | null>(null);
    
    
    useEffect(() => {
        // Scroll to the top when the dialog opens
        window.scrollTo({ top: 0, left: 0, behavior: 'smooth' });
    }, []);
    interface ColumnDefinition {
        field: string;
        headerName: string;
        minWidth: number;
        maxWidth: number;
        resizable: boolean;
        sortable: boolean;
        cellRenderer: (params: any) => JSX.Element;
    }
    const handleColumnReorder = (draggedIndex: number, targetIndex: number) => {
        const draggedItems = columns[draggedIndex];
        const newColumns: IColumn[] = [...columns];
    
        // insert before the dropped item
        newColumns.splice(draggedIndex, 1);
        newColumns.splice(targetIndex, 0, draggedItems);
        setColumns(newColumns);
      };
    
      const getColumnReorderOptions = (): IColumnReorderOptions => {
        return {
          handleColumnReorder
        };
      };

    

    const [columns, setColumns] = useState<IColumn[]>([
        {
            key: 'file_type',
            name: 'File Type',
            isResizable: true,
            className: styles.fileIconCell,
            iconClassName: styles.fileIconHeaderIcon,
            ariaLabel: 'Column operations for File type, Press to sort on File type',
            iconName: 'Page',
            isIconOnly: true,
            fieldName: 'name',
            minWidth: 16,
            maxWidth: 16,
            onColumnClick: onColumnClick,
            columnActionsMode: ColumnActionsMode.hasDropdown,
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
            columnActionsMode: ColumnActionsMode.hasDropdown,
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
            columnActionsMode: ColumnActionsMode.hasDropdown,
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
            columnActionsMode: ColumnActionsMode.hasDropdown,
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
            columnActionsMode: ColumnActionsMode.hasDropdown,
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
            columnActionsMode: ColumnActionsMode.hasDropdown,
        },
        {
            key: 'modified_timestamp',
            name: 'Last Updated',
            fieldName: 'modified_timestamp',
            minWidth: 90,
            columnActionsMode: ColumnActionsMode.hasDropdown,
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
            isResizable: true,
            isCollapsible: true,
            ariaLabel: 'Column operations for status detail',
            data: 'string',
            onColumnClick: onColumnClick,
            columnActionsMode: ColumnActionsMode.hasDropdown,
            onRender: (item: IDocument) => (
                <TooltipHost content={`${item.state_description} `}>
                    <span onClick={() => onStateColumnClick(item)} style={{ cursor: 'pointer' }}>
                        {item.state_description}
                    </span>
                </TooltipHost>
            )
        }
    ]);

    const columnRefs = useRef<(HTMLDivElement | null)[]>([]);
    useEffect(() => {
        columnRefs.current.forEach((ref, index) => {
            if (ref) {
                ref.addEventListener('focus', () => setFocusedColumnIndex(index));
            }
        });

        return () => {
            columnRefs.current.forEach((ref, index) => {
                if (ref) {
                    ref.removeEventListener('focus', () => setFocusedColumnIndex(index));
                }
            });
        };
    }, [columns]);

    const refMap = useRef<{ [key: string]: HTMLDivElement | null }>({});

    
    

    const refreshRef = useRef<HTMLDivElement>(null);
    const deleteRef = useRef<HTMLDivElement>(null);
    const resubmitRef = useRef<HTMLDivElement>(null);

    const handleKeyDown = (e: KeyboardEvent, onClick: () => void) => {
        if (e.key === " " || e.key === "Enter" || e.key === "Spacebar") {
            onClick();
        }
    };

    const onColumnResize = (column?: IColumn, newWidth?: number, columnIndex?: number) => {
        const newColumns = [...columns];
        if (columnIndex !== undefined) {
            if (column) {
                console.log('Resizing column:', column.key);
                newColumns[columnIndex] = { ...column, maxWidth: newWidth, key: column.key || '' };
            }
        }
        setColumns(newColumns);
    };
    useEffect(() => {
        const refreshButton = refreshRef.current;
        const deleteButton = deleteRef.current;
        const resubmitButton = resubmitRef.current;

        if (refreshButton) {
            refreshButton.addEventListener('keydown', (e) => handleKeyDown(e, onRefresh));
        }
        if (deleteButton) {
            deleteButton.addEventListener('keydown', (e) => handleKeyDown(e, handleDeleteClick));
        }
        if (resubmitButton) {
            resubmitButton.addEventListener('keydown', (e) => handleKeyDown(e, handleResubmitClick));
        }

        return () => {
            if (refreshButton) {
                refreshButton.removeEventListener('keydown', (e) => handleKeyDown(e, onRefresh));
            }
            if (deleteButton) {
                deleteButton.removeEventListener('keydown', (e) => handleKeyDown(e, handleDeleteClick));
            }
            if (resubmitButton) {
                resubmitButton.removeEventListener('keydown', (e) => handleKeyDown(e, handleResubmitClick));
            }
        };
    }, [onRefresh, handleDeleteClick, handleResubmitClick]);

    const [isPopupVisible, setIsPopupVisible] = useState(false);
    const handleColumnKeyDownEnter = (event: React.KeyboardEvent, columnIndex: number) => {
        if (event.key === 'Enter') {
            setFocusedColumnIndex(columnIndex);
            setIsPopupVisible(true);
        }
    };
    


    const handleColumnKeyDown = (event: React.KeyboardEvent, column: IColumn, columnIndex: number) => {
        const increment = 10; // Amount to resize by
        if (event.ctrlKey && event.key === 'ArrowRight') {
            onColumnResize(column, (column.maxWidth || column.minWidth) + increment, columnIndex);
        } else if (event.key === 'ArrowLeft') {
            onColumnResize(column, (column.maxWidth || column.minWidth) - increment, columnIndex);
        }
    };
    const hasRecords = items.length > 0;

    const onRenderColumnHeader = (props: any, defaultRender?: any) => {
        return (
            <div 
            tabIndex={0} 
            onFocus={() => setFocusedColumnIndex(props.columnIndex)}
            style={{ outline: focusedColumnIndex === props.columnIndex ? '2px solid blue' : 'none' }}
            onKeyDown={(event) => handleColumnKeyDown(event as React.KeyboardEvent, props.column, props.columnIndex
            

            )}>
                {defaultRender(props)}
            </div>
        );
    };
    
    
    // Column Definitions: Defines & controls grid columns.
   


    

    
      const [dialogOpen, setDialogOpen] = useState(false);

      const [preferredWidth, setPreferredWidth] = useState<number>(100);

      const toggleDialog = (api?: Column) => {
        setDialogOpen(!dialogOpen);
        if (api) {
            setColumnApi(api);
        }
    };
      const handleKeyDownMenu = (event: React.KeyboardEvent<HTMLSpanElement>, columnid: string) => {
          if (event.key === 'Enter' || event.key === ' ') {
            setSelectedColumnId(columnid);
              event.preventDefault();
              toggleDialog();
          }
      };
    
      

    
    const GRID_CELL_CLASSNAME = "ag-header-cell";
    function getAllFocusableElementsOf(el: HTMLElement) {
        return Array.from<HTMLElement>(
          el.querySelectorAll(
            'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])',
          ),
        ).filter((focusableEl) => {
          return focusableEl.tabIndex !== -1;
        });
      }
      function getEventPath(event: Event): HTMLElement[] {
        const path: HTMLElement[] = [];
        let currentTarget: any = event.target;
        while (currentTarget) {
          path.push(currentTarget);
          currentTarget = currentTarget.parentElement;
        }
        return path;
      }
    

    const [sortAscending, setSortAscending] = useState(false);
    const [sortDescending, setSortDescending] = useState(false);
    const [moveLeft, setMoveLeft] = useState(false);
    const [moveRight, setMoveRight] = useState(false);
    const [sortedItems, setSortedItems] = React.useState<IDocument[]>(items);
    const [isDialogHidden, setIsDialogHidden] = React.useState(true);
    const textfieldRef = React.useRef<ITextField>(null);
    const columnToEdit = React.useRef<IColumn | null>(null);
    const clickHandler = React.useRef<string>(RESIZE);
    const [contextualMenuProps, setContextualMenuProps] = React.useState<IContextualMenuProps | undefined>(undefined);
    const detailsListRef = React.useRef<IDetailsList>(null);
    const input = React.useRef<number | null>(null);
    const focusZoneRef = React.useRef<IFocusZone>(null);
    const [isColumnReorderEnabled, setIsColumnReorderEnabled] = React.useState<boolean>(true);
    const onRenderItemColumn = (item: IDocument, index: number, column: IColumn): JSX.Element | string => {
        const key = column.key as keyof IDocument;
        if (key === 'name') {
          return (
            <Link data-selection-invoke={true} underline>
              {item[key]}
            </Link>
          );
        }
        return String(item[key]);
      };
    
      const resizeColumn = (column: IColumn) => {
        columnToEdit.current = column;
        clickHandler.current = RESIZE;
        showDialog();
      };
    
      const reorderColumn = (column: IColumn) => {
        columnToEdit.current = column;
        clickHandler.current = REORDER;
        showDialog();
      };
    
      const confirmDialog = () => {
        const detailsList = detailsListRef.current;
    
        if (textfieldRef.current) {
          input.current = Number(textfieldRef.current.value);
        }
    
        if (columnToEdit.current && input.current && detailsList) {
          if (clickHandler.current === RESIZE) {
            const width = input.current;
            detailsList.updateColumn(columnToEdit.current, { width });
          } else if (clickHandler.current === REORDER) {
            const targetIndex = selection.mode ? input.current + 1 : input.current;
            detailsList.updateColumn(columnToEdit.current, { newColumnIndex: targetIndex });
          }
        }
    
        input.current = null;
        hideDialog();
      };
    
      
    
      const getContextualMenuProps = (ev: React.MouseEvent<HTMLElement>, column: IColumn): IContextualMenuProps => {
        const items = [
          { key: 'resize', text: 'Resize', onClick: () => resizeColumn(column) },
          { key: 'reorder', text: 'Reorder', onClick: () => reorderColumn(column) },
          { key: 'sort', text: 'Sort', onClick: () => sortColumn(column) },
        ];
    
        return {
          items,
          target: ev.currentTarget as HTMLElement,
          gapSpace: 10,
          isBeakVisible: true,
          onDismiss: onHideContextualMenu,
        };
      };
    
      const hideDialog = () => setIsDialogHidden(true);
    
      const showDialog = () => setIsDialogHidden(false);
    
      const sortColumn = (column: IColumn): void => {
        let isSortedDescending = column.isSortedDescending;
    
        // If we've sorted this column, flip it.
        if (column.isSorted) {
          isSortedDescending = !isSortedDescending;
        }
    
        // Sort the items.
        const newSortedItems = copyAndSort(sortedItems, column.fieldName!, isSortedDescending);
        console.log('Sorted items:', newSortedItems);
        columns.map(col => {
          col.isSorted = col.key === column.key;
    
          if (col.isSorted) {
            col.isSortedDescending = isSortedDescending;
          }
    
          return col;
        });
        
        setSortedItems(newSortedItems);
      };
    
      const onHideContextualMenu = React.useCallback(() => setContextualMenuProps(undefined), []);
    
      const [draggedItem, setDraggedItem] = React.useState(undefined);
      const [selection] = React.useState(new Selection());
      const [draggedIndex, setDraggedIndex] = React.useState(-1);

    
      // Initialize Selection with items
      useEffect(() => {
          selectionRef.current.setItems(itemList, false);
      }, [itemList]);
  

      const insertBeforeItem = React.useCallback(
        (item: IDocument) => {
          const draggedItems = selection.isIndexSelected(draggedIndex)
            ? (selection.getSelection() as IDocument[])
            : [draggedItem!];
    
          const insertIndex = items.indexOf(item);
          const listItems = items.filter(itm => draggedItems.indexOf(itm) === -1);
    
          items.splice(insertIndex, 0, ...draggedItems);
    
          setItems(listItems);
        },
        [draggedIndex, draggedItem, items, selection],
      );
    

      React.useEffect(() => {
        //sets keyboard focus back to header of column that was reordered.
        if (clickHandler.current === REORDER && columnToEdit.current) {
          let columnHeaderReorderedIndex = -1;
          for (let i = 0; i < columns.length; i++) {
            if (columns[i].key === columnToEdit.current.key) {
              columnHeaderReorderedIndex = i;
              break;
            }
          }
          const element = getDocument()?.querySelector(`[id*=${columns[columnHeaderReorderedIndex].key}]`);
          const columnHeaderReordered = (element as HTMLElement) ?? undefined;
    
          focusZoneRef.current?.focusElement(columnHeaderReordered);
        }
      }, [columns]);
    
      const getDragDropEvents = React.useCallback((): IDragDropEvents => {
        return {
          canDrop: (dropContext?: IDragDropContext, dragContext?: IDragDropContext) => {
            return true;
          },
          canDrag: (item?: any) => {
            return true;
          },
          onDragEnter: (item?: any, event?: DragEvent) => {
            // return string is the css classes that will be added to the entering element.
            return dragEnterClass;
          },
          onDragLeave: (item?: any, event?: DragEvent) => {
            return;
          },
          onDrop: (item?: any, event?: DragEvent) => {
            if (draggedItem) {
              insertBeforeItem(item);
            }
          },
          onDragStart: (item?: any, itemIndex?: number, selectedItems?: any[], event?: MouseEvent) => {
            setDraggedItem(item);
            setDraggedIndex(itemIndex!);
          },
          onDragEnd: (item?: any, event?: DragEvent) => {
            setDraggedItem(undefined);
            setDraggedIndex(-1);
          },
        };
      }, [draggedItem, insertBeforeItem]);
    
      const dragDropEvents = getDragDropEvents();
    
      const resizeDialogContentProps = {
        type: DialogType.normal,
        title: 'Resize Column',
        closeButtonAriaLabel: 'Close',
        subText: 'Enter desired column width pixels:',
      };
    
      const reorderDialogContentProps = {
        type: DialogType.normal,
        title: 'Reorder Column',
        closeButtonAriaLabel: 'Close',
        subText: 'Enter which column to move this to (use 1-based indexing):',
      };
    
      const modalProps = {
        titleAriaId: 'Dialog',
        subtitleAriaId: 'Dialog sub',
        isBlocking: false,
        styles: dialogStyles,
      };
      const onColumnKeyDown = React.useCallback(
        (ev: React.KeyboardEvent, column: IColumn): void => {
          const detailsList = detailsListRef.current;
    
          if (ev.shiftKey) {
            const indexOffset = 1 + selection.mode ? 1 : 0;
            const columnIndex = columns.findIndex(x => x.key === column.key) + indexOffset;
            switch (ev.key) {
              case 'ArrowLeft':
                if (columnIndex > 0) {
                  detailsList?.updateColumn(column, { newColumnIndex: columnIndex + indexOffset - 1 });
                }
                break;
              case 'ArrowRight':
                if (columnIndex < columns.length - 1) {
                  detailsList?.updateColumn(column, { newColumnIndex: columnIndex + indexOffset + 1 });
                }
                break;
            }
          }
          if (ev.ctrlKey) {
            ev.preventDefault();
            switch (ev.key) {
              case 'ArrowLeft':
                detailsList?.updateColumn(column, {
                  width: column?.currentWidth ? column?.currentWidth * 0.9 : column.minWidth,
                });
                break;
              case 'ArrowRight':
                detailsList?.updateColumn(column, {
                  width: column?.currentWidth ? column?.currentWidth * 1.1 : column.minWidth,
                });
                break;
            }
          }
        },
        [columns, selection.mode],
      );

    // Fetch data & update rowData state
    return (
        
        <div>
            <AriaLiveAnnouncer>
            <div className={styles.buttonsContainer}>
                <div role="button" ref={refreshRef} className={`${styles.refresharea} ${styles.divSpacing}`} onClick={onRefresh} tabIndex={0} aria-label="Refresh">
                    <ArrowClockwise24Regular className={styles.refreshicon} />
                    <span className={`${styles.refreshtext} ${styles.centeredText}`}>Refresh</span>
                </div>
                <div 
                    ref={deleteRef}
                    role="button"
                    tabIndex={hasRecords ? 0 : -1}
                    onClick={hasRecords ? handleDeleteClick : undefined}
                    style={{ cursor: hasRecords ? 'pointer' : 'not-allowed', opacity: hasRecords ? 1 : 0.5 }}
                    aria-disabled={!hasRecords}
                    className={`${styles.refresharea} ${styles.divSpacing}`}
                    aria-label="Delete"
                >
                    <Delete24Regular className={styles.refreshicon} />
                    <span className={`${styles.refreshtext} ${styles.centeredText}`}>Delete</span>
                </div>
                
                <StatusMessage message={status} />
                <div ref={resubmitRef}
                    role="button"
                    tabIndex={hasRecords ? 0 : -1}
                    onClick={hasRecords ? handleResubmitClick : undefined}
                    style={{ cursor: hasRecords ? 'pointer' : 'not-allowed', opacity: hasRecords ? 1 : 0.5 }}
                    aria-disabled={!hasRecords}
                    aria-label="Resubmit"
                    className={`${styles.refresharea} ${styles.divSpacing}`}
                >
                    <ArrowClockwise24Regular className={styles.refreshicon} />
                    <span className={`${styles.refreshtext} ${styles.centeredText}`}>Resubmit</span>
                </div>
                
            </div>
            <span className={styles.footer}>{"(" + items.length as string + ") records."}</span>
            <DetailsList
                                componentRef={detailsListRef}
                                focusZoneProps={{ componentRef: focusZoneRef }}
                                items={sortedItems}
                                compact={true}
                                columns={columns.map(x => ({ ...x, onColumnKeyDown }))}
                                selection={selectionRef.current}
                                selectionMode={SelectionMode.multiple} // Allow multiple selection
                                getKey={getKey}
                                setKey="items"
                                layoutMode={DetailsListLayoutMode.justified}
                                isHeaderVisible={true}
                                onItemInvoked={onItemInvoked}
                                ariaLabelForSelectionColumn="Toggle selection"
                                ariaLabelForSelectAllCheckbox="Toggle selection for all items"
                                onColumnResize={onColumnResize}
                                onRenderDetailsHeader={onRenderColumnHeader}
                                dragDropEvents={dragDropEvents}
                                columnReorderOptions={isColumnReorderEnabled ? getColumnReorderOptions() : undefined}
                            />
                            {contextualMenuProps && <ContextualMenu {...contextualMenuProps} />}
                            <Dialog
                                hidden={isDialogHidden}
                                onDismiss={hideDialog}
                                dialogContentProps={clickHandler.current === RESIZE ? resizeDialogContentProps : reorderDialogContentProps}
                                modalProps={modalProps}
                            >
                                <TextField
                                componentRef={textfieldRef}
                                ariaLabel={clickHandler.current === RESIZE ? 'Enter column width' : 'Enter column index '}
                                />
                                <DialogFooter>
                                <PrimaryButton onClick={confirmDialog} text={clickHandler.current} />
                                <DefaultButton onClick={hideDialog} text="Cancel" />
                                </DialogFooter>
                            </Dialog>
            
            {items.length > 0 && (
                <span className={styles.footer}>{"(" + items.length + ") records."}</span>
            )}

            <Dialog
                    hidden={!contextMenuVisible}
                    onDismiss={() => setContextMenuVisible(false)}
                    dialogContentProps={{
                        type: DialogType.normal,
                        title: 'Column Actions',
                        subText: 'Select actions to perform on the column.'
                    }}
                    modalProps={{
                        isBlocking: true,
                        styles: { main: { maxWidth: 450 } }
                    }}
                >
                    
                    <DialogFooter>
                        <DefaultButton onClick={() => setContextMenuVisible(false)} text="Close" />
                    </DialogFooter>
                </Dialog>
           
            <Dialog
                hidden={!dialogOpen}
                onDismiss={() => setDialogOpen(false)}
                dialogContentProps={{
                    type: DialogType.normal,
                    title: 'Column Width',
                    subText: 'Select actions to perform on the column.'
                }}
                modalProps={{
                    isBlocking: false,
                    styles: { main: { maxWidth: 450 } }
                }}
            >
                <div>
                   <label>
                        Preferred Width:
                        <input
                            type="number"
                            min="50"
                            max={maxColumnWidth}
                            step="10"
                            value={currentColumnWidth}
                            onChange={handleWidthChange}
                        />
                    </label>
                </div>
                
            </Dialog> 
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
                    <PrimaryButton onClick={DoDeletion} text="Delete" />
                    <DefaultButton onClick={() => setIsDeleteDialogVisible(false)} text="Cancel" />
                </DialogFooter>
                <div aria-live="assertive" aria-atomic="true"
                    className={styles.visuallyHidden}>
                {message}
                </div>
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
                </AriaLiveAnnouncer>
        </div>
    );
}
