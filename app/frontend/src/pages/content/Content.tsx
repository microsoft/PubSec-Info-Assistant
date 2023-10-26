// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import { useState } from 'react';
import { Pivot,
    PivotItem,
    TooltipHost,
    ITooltipHostStyles} from "@fluentui/react";
import { useId } from '@fluentui/react-hooks';
import { Info16Regular } from '@fluentui/react-icons';
import { FilePicker } from "../../components/filepicker/file-picker";
import { FileStatus } from "../../components/FileStatus/FileStatus";
import { TagPickerInline } from "../../components/TagPicker/TagPicker"

import styles from "./Content.module.css";
import { FolderPicker } from '../../components/FolderPicker/FolderPicker';

export interface IButtonExampleProps {
    // These are set based on the toggles shown above the examples (not needed in real code)
    disabled?: boolean;
    checked?: boolean;
  }

const Content = () => {
    const tooltipId = useId('tooltip');
    const hostStyles: Partial<ITooltipHostStyles> = { root: { display: 'inline-block' } };
    const [selectedKey, setSelectedKey] = useState<string | undefined>(undefined);
    
    return (
        <div className={styles.contentArea} >
            <Pivot aria-label="Upload Files Section" className={styles.topPivot}>
                <PivotItem headerText="Upload Files" aria-label="Upload Files Tab">
                    <div className={styles.App} >
                        <FolderPicker allowFolderCreation={true} />
                        <div className={styles.tagArea}>
                            <div className={styles.tagSelection}>
                                <TagPickerInline allowNewTags={true} />
                                <TooltipHost content="Tags to append to each document uploaded below."
                                        styles={hostStyles}
                                        id={tooltipId}>
                                    <Info16Regular></Info16Regular>
                                </TooltipHost>
                            </div>

                        </div>
                        <FilePicker folderPath={selectedKey || ""}/>
                    </div>
                </PivotItem>
                <PivotItem headerText="Upload Status" aria-label="Upload Status Tab">
                    <FileStatus className=""/>
                </PivotItem>
            </Pivot>
        </div>
    );
};
    
export default Content;