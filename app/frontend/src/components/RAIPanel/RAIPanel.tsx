// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import { Options16Filled, ArrowSync16Filled, Briefcase16Filled, Globe16Filled } from "@fluentui/react-icons";

import styles from "./RAIPanel.module.css";
import { Icon } from "@fluentui/react";
import { Approaches, ChatMode } from "../../api";

interface Props {
    approach?: Approaches;
    chatMode?: ChatMode;
    onAdjustClick?: () => void;
    onRegenerateClick?: () => void;
    onWebSearchClicked?: () => void;
    onRagSearchClicked?: () => void;
    onWebCompareClicked?: () => void;
    onRagCompareClicked?: () => void;
}

export const RAIPanel = ({approach, chatMode, onAdjustClick, onRegenerateClick, onWebSearchClicked, onRagSearchClicked, onWebCompareClicked, onRagCompareClicked }: Props) => {
    return (
        <div className={styles.adjustInputContainer}>
            <div className={styles.adjustInput} onClick={onAdjustClick}>
                <Options16Filled primaryFill="rgba(133, 133, 133, 1)" />
                <span className={styles.adjustInputText}>Adjust</span>
            </div>
            <div className={styles.adjustInput} onClick={onRegenerateClick}>
                <ArrowSync16Filled primaryFill="rgba(133, 133, 133, 1)" />
                <span className={styles.adjustInputText}>Regenerate</span>
            </div>
            {(approach == Approaches.ChatWebRetrieveRead && chatMode == ChatMode.WorkPlusWeb) &&
                    <>
                        <div className={styles.adjustInput} onClick={onRagSearchClicked}>
                            <Briefcase16Filled primaryFill="rgba(133, 133, 133, 1)" />
                            <span className={styles.adjustInputText}>Search Work</span>
                        </div>
                        <div className={styles.adjustInput} onClick={onRagCompareClicked}>
                            <Briefcase16Filled primaryFill="rgba(133, 133, 133, 1)" />
                            <span className={styles.adjustInputText}>Compare with Work</span>
                        </div>
                    </>
            }
            {(approach == Approaches.ReadRetrieveRead && chatMode == ChatMode.WorkPlusWeb) &&
                    <>
                        <div className={styles.adjustInput} onClick={onWebSearchClicked}>
                            <Globe16Filled primaryFill="rgba(133, 133, 133, 1)" />
                            <span className={styles.adjustInputText}>Search Web</span>
                        </div>
                        <div className={styles.adjustInput} onClick={onWebCompareClicked}>
                            <Globe16Filled primaryFill="rgba(133, 133, 133, 1)" />
                            <span className={styles.adjustInputText}>Compare with Web</span>
                        </div>
                    </>
            }
        </div>
    );
};