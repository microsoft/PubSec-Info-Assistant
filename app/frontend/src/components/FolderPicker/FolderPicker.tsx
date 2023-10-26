// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import { useState, useEffect } from 'react';
import { useId, useBoolean } from '@fluentui/react-hooks';
import { ComboBox,
    IComboBoxOption,
    IComboBoxStyles,
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
}

export const FolderPicker = ({allowFolderCreation}: Props) => {

    const buttonId = useId('targetButton');
    const tooltipId = useId('folderpicker-tooltip');
    const textFieldId = useId('textField');

    const [teachingBubbleVisible, { toggle: toggleTeachingBubbleVisible }] = useBoolean(false);
    const [selectedKey, setSelectedKey] = useState<string | undefined>(undefined);
    const [options, setOptions] = useState<IComboBoxOption[]>([]);
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
            setSelectedKey(textField.defaultValue);
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
            for await (const item of containerClient.listBlobsByHierarchy(delimiter, {
                prefix,
              })) {
                // Check if the item is a folder
                if (item.kind === "prefix") {
                  // Get the folder name and add to the dropdown list
                  var folderName = item.name.slice(0,-1);
                  var newOptions = options;
                  newOptions.push({key: folderName, text: folderName});
                  setOptions(newOptions);
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

    return (
        <div className={styles.folderArea}>
            <div className={styles.folderSelection}>
                <ComboBox
                    selectedKey={selectedKey}
                    label="Folder Selection"
                    options={options}
                    styles={comboBoxStyles}
                />
                <TooltipHost content="A folder to upload documents into."
                        styles={hostStyles}
                        id={tooltipId}>
                    <Info16Regular></Info16Regular>
                </TooltipHost>
            </div>
            {allowFolderCreation ? (
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