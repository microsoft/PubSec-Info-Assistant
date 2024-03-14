// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.
import { useState, useEffect } from 'react';
import { TagPicker, ITag, IBasePickerSuggestionsProps} from '@fluentui/react/lib/Pickers';
import { TooltipHost,
  ITooltipHostStyles} from "@fluentui/react";
import { Info16Regular } from '@fluentui/react-icons';
import { mergeStyles } from '@fluentui/react/lib/Styling';
import { useId } from '@fluentui/react-hooks';
import { getAllTags } from "../../api";

import styles from "./TagPicker.module.css";

var allowAddNew = false;

interface Props {
    allowNewTags?: boolean;
    onSelectedTagsChange: (selectedTags: ITag[]) => void;
    preSelectedTags?: ITag[];
    hide?: boolean;
}

export const TagPickerInline = ({allowNewTags, onSelectedTagsChange, preSelectedTags, hide}: Props) => {

    const pickerId = useId('tag-inline-picker');
    const tooltipId = useId('tagpicker-tooltip');
    const hostStyles: Partial<ITooltipHostStyles> = { root: { display: 'inline-block' } };
    const newItem = mergeStyles({ color: '#f00', background: '#ddf', padding: '10px' });
    const existingItem = mergeStyles({ color: '#222', padding: '10px' });

    const [selectedTags, setSelectedTags] = useState<ITag[]>([]);
    const [tags, setTags] = useState<ITag[]>([]);
    const getTextFromItem = (item: ITag) => item.name;

    allowAddNew = allowNewTags as boolean;

    const listContainsTagList = (tag: ITag, tagList?: ITag[]): boolean => {
        if (!tagList || !tagList.length || tagList.length === 0) {
          return false;
        }
        return tagList.some((compareTag: ITag) => compareTag.key === tag.key);
      };
    
    const filterSuggestedTags = (filterText: string, tagList: ITag[] | undefined): ITag[] => {
        var existingMatches = filterText
        ? tags.filter(
            tag => tag.name.toLowerCase().indexOf(filterText.toLowerCase()) === 0 && !listContainsTagList(tag, tagList),
          )
        : [];
    
        if (allowAddNew) {
            return existingMatches.some(a=> a.key === filterText)
            ? existingMatches :
            [{ key: filterText, name: filterText, isNewItem: true } as ITag].concat(existingMatches);
        }
        else {  
            return existingMatches;
        }
    };
    
    const onItemSelected = (item: any | undefined): ITag | PromiseLike<ITag> | null => {
        const selected = selectedTags;
        if(item && item.isNewItem) {
            item.isNewItem = false;
            var newTags = tags;
            newTags.push(item);
            setTags(newTags);
        }
        return item as ITag;
      };
    
    const onRenderSuggestionsItem = (props: any, itemProps: any): JSX.Element => {
        if (allowAddNew) {
            return <div className={props.isNewItem ? newItem : existingItem} key={props.key}>
          {props.name}
          </div>;
        }
        else {
            return <div className={existingItem} key={props.key}>
          {props.name}
          </div>;
        }
        
      };

    const pickerSuggestionsProps: IBasePickerSuggestionsProps = {
      suggestionsHeaderText: 'Existing Tags',
      noResultsFoundText: allowAddNew ? 'Press Enter to add as a new tag' : 'No matching tag found',
    };

    async function fetchTagsfromCosmos() {
      try {
        const response = await getAllTags();
        var newTags: ITag[] = [];
        response.tags.split(",").forEach((tag: string) => {
          const trimmedTag = tag.trim();
          if (trimmedTag !== "" && !newTags.some(t => t.key === trimmedTag)) {
            const newTag: any = { key: trimmedTag, name: trimmedTag, isNewItem: false };
            newTags.push(newTag);
          }
        });
        setTags(newTags);
        if (preSelectedTags !== undefined && preSelectedTags.length > 0) {
          setSelectedTags(preSelectedTags);
          onSelectedTagsChange(preSelectedTags);
        }
        else {
          setSelectedTags([]);
          onSelectedTagsChange([]);
        }
      }
      catch (error) {
        console.log(error);
      }
    }

    const onChange = (items?: ITag[] | undefined) => {
      if (items) {
        setSelectedTags(items);
        onSelectedTagsChange(items);
      }
    };

    useEffect(() => {
      fetchTagsfromCosmos();
  }, []);
    
    return (
      <div  className={hide? styles.hide : styles.tagArea}>
        <div className={styles.tagSelection}>
          <div className={allowAddNew ? styles.rootClass : styles.rootClassFilter}>
            <label htmlFor={pickerId}>Tags</label>
            <TagPicker
                className={styles.tagPicker}
                removeButtonAriaLabel="Remove"
                selectionAriaLabel="Existing tags"
                onResolveSuggestions={filterSuggestedTags}
                onRenderSuggestionsItem={onRenderSuggestionsItem}
                getTextFromItem={getTextFromItem}
                pickerSuggestionsProps={pickerSuggestionsProps}
                itemLimit={10}
                // this option tells the picker's callout to render inline instead of in a new layer
                pickerCalloutProps={{ doNotLayer: false }}
                inputProps={{
                    id: pickerId
                }}
                onItemSelected={onItemSelected}
                selectedItems={selectedTags}
                onChange={onChange}
            />
          </div>
          <TooltipHost content={allowAddNew ? "Tags to append to each document uploaded below." : "Tags to filter documents by."}
                    styles={hostStyles}
                    id={tooltipId}>
            <Info16Regular></Info16Regular>
          </TooltipHost>
        </div>
      </div>
  );
};
