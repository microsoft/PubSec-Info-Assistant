// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import { useState } from 'react';
import { Pivot,
    PivotItem } from "@fluentui/react";
import { ITag } from '@fluentui/react/lib/Pickers';
import { FilePicker } from "../../components/filepicker/file-picker";
import { FileStatus } from "../../components/FileStatus/FileStatus";
import { TagPickerInline } from "../../components/TagPicker/TagPicker"
import { FolderPicker } from '../../components/FolderPicker/FolderPicker';
import { ApproachesButtonGroup } from '../../components/ApproachesButtonGroup/ApproachesButtonGroup';

import styles from "./Content.module.css";

export interface IButtonExampleProps {
    // These are set based on the toggles shown above the examples (not needed in real code)
    disabled?: boolean;
    checked?: boolean;
  }

const Content = () => {
    const [selectedKey, setSelectedKey] = useState<string | undefined>(undefined);
    const [selectedTags, setSelectedTags] = useState<string[] | undefined>(undefined);
    const [selectedApproach, setSelectedApproach] = useState<number | undefined>(undefined);

    const onSelectedKeyChanged = (selectedFolder: string[]) => {
        setSelectedKey(selectedFolder[0]);
    };

    const onSelectedTagsChanged = (selectedTags: ITag[]) => {
        setSelectedTags(selectedTags.map((tag) => tag.name));
    }

    const onSelectedApproach = (approach: number) => {
        setSelectedApproach(approach);
        alert(approach)
    }

    const handleLinkClick = (item?: PivotItem) => {
        setSelectedKey(undefined);
    };    

    return (
        <div className={styles.contentArea} >
            <Pivot aria-label="Upload Files Section" className={styles.topPivot} onLinkClick={handleLinkClick}>
                <PivotItem headerText="Upload Files" aria-label="Upload Files Tab">
                    <div className={styles.App} >
                        <FolderPicker allowFolderCreation={true} onSelectedKeyChange={onSelectedKeyChanged}/>
                        <TagPickerInline allowNewTags={true} onSelectedTagsChange={onSelectedTagsChanged}/>
                        <FilePicker folderPath={selectedKey || ""} tags={selectedTags || []}/>
                    </div>
                </PivotItem>
                <PivotItem headerText="Upload Status" aria-label="Upload Status Tab">
                    <FileStatus className=""/>
                </PivotItem>
                <PivotItem headerText="Approach" aria-label="Approach Tab">
                    <ApproachesButtonGroup className="" onClick={onSelectedApproach}/>
                </PivotItem>
            </Pivot>
        </div>
    );
};
    
export default Content;