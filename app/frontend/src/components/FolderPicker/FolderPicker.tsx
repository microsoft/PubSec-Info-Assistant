// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import { useState, useEffect } from 'react';
import { useId, useBoolean } from '@fluentui/react-hooks';
import { ComboBox,
    IComboBox,
    IComboBoxOption,
    IComboBoxStyles,
    SelectableOptionMenuItemType,
    TooltipHost,
    ITooltipHostStyles,
    ActionButton, 
    DirectionalHint} from "@fluentui/react";
import { TeachingBubble, ITeachingBubbleStyles } from '@fluentui/react/lib/TeachingBubble';
import { Info16Regular } from '@fluentui/react-icons';
import { ITextFieldStyleProps, ITextFieldStyles, TextField } from '@fluentui/react/lib/TextField';
import { ILabelStyles, ILabelStyleProps } from '@fluentui/react/lib/Label';
import { IIconProps } from '@fluentui/react';
import { IButtonProps } from '@fluentui/react/lib/Button';
import { BlobServiceClient } from "@azure/storage-blob";

import { getBlobClientUrl } from "../../api";
import styles from "./FolderPicker.module.css";

var allowNewFolders = false;

interface Props {
    allowFolderCreation?: boolean;
    onSelectedKeyChange: (selectedFolders: string[]) => void;
    preSelectedKeys?: string[];
}

export const FolderPicker = ({allowFolderCreation, onSelectedKeyChange, preSelectedKeys}: Props) => {

    const buttonId = useId('targetButton');
    const tooltipId = useId('folderpicker-tooltip');
    const textFieldId = useId('textField');

    const [teachingBubbleVisible, { toggle: toggleTeachingBubbleVisible }] = useBoolean(false);
    const [selectedKeys, setSelectedKeys] = useState<string[]>([]);
    const [options, setOptions] = useState<IComboBoxOption[]>([]);
    const selectableOptions = options.filter(
        option =>
          (option.itemType === SelectableOptionMenuItemType.Normal || option.itemType === undefined) && !option.disabled,
      );
    const comboBoxStyles: Partial<IComboBoxStyles> = { root: { maxWidth: 300 } };
    const hostStyles: Partial<ITooltipHostStyles> = { root: { display: 'inline-block' } };
    const addFolderIcon: IIconProps = { iconName: 'Add' };

    allowNewFolders = allowFolderCreation as boolean;

    const teachingBubbleStyles: Partial<ITeachingBubbleStyles> = {
        content: {
            background: "#d3d3d3",
            borderColor: "#696969"
        },
        headline: {
            color: "#696969"
        },
    }
    
    const teachingBubblePrimaryButtonClick = (() => {
        var textField = document.getElementById(textFieldId) as HTMLInputElement;
        if (textField.defaultValue == null || textField.defaultValue == "") {
            alert('Please enter a folder name.');
        } else {
            // add the folder to the dropdown list and select it
            // This will be passed to the file-picker component to determine the folder to upload to
            var currentOptions = options;
            currentOptions.push({key: textField.defaultValue, text: textField.defaultValue});
            setOptions(currentOptions)
            setSelectedKeys([textField.defaultValue]);
            onSelectedKeyChange([textField.defaultValue]);
            toggleTeachingBubbleVisible();
        }
    });

    const examplePrimaryButtonProps: IButtonProps = {
        children: 'Create folder',
        onClick: teachingBubblePrimaryButtonClick,
    };

    async function fetchBlobFolderData() {
        try {
            const blobClientUrl = await getBlobClientUrl();
            const blobServiceClient = new BlobServiceClient(blobClientUrl);
            var containerClient = blobServiceClient.getContainerClient("upload");
            const delimiter = "/";
            const prefix = "";
            var newOptions: IComboBoxOption[] = allowNewFolders ? [] : [(
                { key: 'selectAll', text: 'Select All', itemType: SelectableOptionMenuItemType.SelectAll }
                )];
            for await (const item of containerClient.listBlobsByHierarchy(delimiter, {
                prefix,
              })) {
                // Check if the item is a folder
                if (item.kind === "prefix") {
                  // Get the folder name and add to the dropdown list
                  var folderName = item.name.slice(0,-1);
                  
                  newOptions.push({key: folderName, text: folderName});
                  setOptions(newOptions);
                }
              }
              if (!allowNewFolders) {
                var filteredOptions = newOptions.filter(
                    option =>
                      (option.itemType === SelectableOptionMenuItemType.Normal || option.itemType === undefined) && !option.disabled,
                  );
                if (preSelectedKeys !== undefined && preSelectedKeys.length > 0) {
                    setSelectedKeys(preSelectedKeys);
                    onSelectedKeyChange(preSelectedKeys);
                }
                else {
                    setSelectedKeys(['selectAll', ...filteredOptions.map(o => o.key as string)]);
                    onSelectedKeyChange(['selectAll', ...filteredOptions.map(o => o.key as string)]);
                }
              } 
        } catch (error) {
            // Handle the error here
            console.log(error);
        }
    }

    useEffect(() => {
        fetchBlobFolderData();
    }, []);

    function getStyles(props: ITextFieldStyleProps): Partial<ITextFieldStyles> {
        const { required } = props;
        return {
          fieldGroup: [
            { width: 300 },
            required && {
              borderColor: "#F8f8ff",
            },
          ],
          subComponentStyles: {
            label: getLabelStyles,
          },
        };
    }
      
    function getLabelStyles(props: ILabelStyleProps): ILabelStyles {
        const { required } = props;
        return {
            root: required && {
                color: "#696969",
            },
        };
    }

    const onChange = (
        event: React.FormEvent<IComboBox>,
        option?: IComboBoxOption,
        index?: number,
        value?: string,
      ): void => {
        const selected = option?.selected;
        const currentSelectedOptionKeys = selectedKeys.filter(key => key !== 'selectAll');
        const selectAllState = currentSelectedOptionKeys.length === selectableOptions.length;
        if (!allowNewFolders) {
            if (option) {
            if (option?.itemType === SelectableOptionMenuItemType.SelectAll) {
                if (selectAllState) {
                    setSelectedKeys([])
                    onSelectedKeyChange([]);
                }
                else {
                    setSelectedKeys(['selectAll', ...selectableOptions.map(o => o.key as string)]);
                    onSelectedKeyChange(['selectAll', ...selectableOptions.map(o => o.key as string)]);
                }
            } else {
                const updatedKeys = selected
                ? [...currentSelectedOptionKeys, option!.key as string]
                : currentSelectedOptionKeys.filter(k => k !== option.key);
                if (updatedKeys.length === selectableOptions.length) {
                updatedKeys.push('selectAll');
                }
                setSelectedKeys(updatedKeys);
                onSelectedKeyChange(updatedKeys);
            }
            }
        }
        else { 
            setSelectedKeys([option!.key as string]);
            onSelectedKeyChange([option!.key as string]);
        }
      };

    return (
        <div className={styles.folderArea}>
            <div className={styles.folderSelection}>
                <ComboBox
                    multiSelect={allowNewFolders? false : true}
                    selectedKey={selectedKeys}
                    label={allowNewFolders? "Folder Selection" : "Folder Selection (Select multiple folders)"}
                    options={options}
                    onChange={onChange}
                    styles={comboBoxStyles}
                />
                <TooltipHost content={allowNewFolders ? "Select a folder to upload documents into" : "Select a folder to filter the search by"}
                        styles={hostStyles}
                        id={tooltipId}>
                    <Info16Regular></Info16Regular>
                </TooltipHost>
            </div>
            {allowNewFolders ? (
                <div className={styles.actionButton}>
                    <ActionButton
                        iconProps={addFolderIcon} 
                        allowDisabledFocus
                        onClick={toggleTeachingBubbleVisible}
                        id={buttonId}>
                        Create new folder
                    </ActionButton>
                    {teachingBubbleVisible && (
                        <TeachingBubble
                        target={`#${buttonId}`}
                        primaryButtonProps={examplePrimaryButtonProps}
                        onDismiss={toggleTeachingBubbleVisible}
                        headline="Create new folder"
                        calloutProps={{ directionalHint: DirectionalHint.topCenter }}
                        styles={teachingBubbleStyles}
                        hasCloseButton={true}
                        >
                        <TextField id={textFieldId} label='Folder Name:' required={true} styles={getStyles}/>
                        </TeachingBubble>
                    )}
                </div>) : ""}
        </div>
    );
};