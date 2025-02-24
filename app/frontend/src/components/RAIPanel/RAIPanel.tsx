// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.
import React, { useEffect, useRef } from 'react';
import { Options16Filled, ArrowSync16Filled, Briefcase16Filled, Globe16Filled, BuildingMultipleFilled } from "@fluentui/react-icons";

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
    tabIndex: number;
}


export const RAIPanel = ({approach, chatMode, onAdjustClick, onRegenerateClick, onWebSearchClicked, onRagSearchClicked, onWebCompareClicked, onRagCompareClicked , tabIndex}: Props) => {
    const adjustButtonRef = useRef<HTMLDivElement>(null);
    const regenerateButtonRef = useRef<HTMLDivElement>(null);

    const handleKeyDown = (e: KeyboardEvent, callback: () => void) => {
        if (e.key === " " || e.key === "Enter" || e.key === "Spacebar") {
            callback();
        }
    };

    useEffect(() => {
        const adjustButton = adjustButtonRef.current;
        const regenerateButton = regenerateButtonRef.current;

        if (adjustButton && onAdjustClick) {
            adjustButton.addEventListener('keydown', (e) => handleKeyDown(e, onAdjustClick));
        }
        if (regenerateButton && onRegenerateClick) {
            regenerateButton.addEventListener('keydown', (e) => handleKeyDown(e, onRegenerateClick));
        }

        return () => {
            if (adjustButton && onAdjustClick) {
                adjustButton.removeEventListener('keydown', (e) => handleKeyDown(e, onAdjustClick));
            }
            if (regenerateButton && onRegenerateClick) {
                regenerateButton.removeEventListener('keydown', (e) => handleKeyDown(e, onRegenerateClick));
            }
        };
    }, [onAdjustClick, onRegenerateClick]);

    return (
        <div className={styles.adjustInputContainer}>
            <div role="button" ref={adjustButtonRef} className={styles.adjustInput} onClick={onAdjustClick} tabIndex={tabIndex}>
                <Options16Filled primaryFill="rgba(133, 133, 133, 1)" />
                <span className={styles.adjustInputText}>Adjust</span>
            </div>
            <div role="button" ref={regenerateButtonRef} className={styles.adjustInput} onClick={onRegenerateClick} tabIndex={tabIndex}>
                <ArrowSync16Filled primaryFill="rgba(133, 133, 133, 1)" />
                <span className={styles.adjustInputText}>Regenerate</span>
            </div>
            {(approach == Approaches.ChatWebRetrieveRead && chatMode == ChatMode.WorkPlusWeb) &&
                    <>
                        <div className={styles.adjustInput} onClick={onRagSearchClicked} tabIndex={tabIndex}>
                            <BuildingMultipleFilled primaryFill="rgba(133, 133, 133, 1)" />
                            <span className={styles.adjustInputText}>Search Work</span>
                        </div>
                        <div className={styles.adjustInput} onClick={onRagCompareClicked} tabIndex={tabIndex}>
                            <BuildingMultipleFilled primaryFill="rgba(133, 133, 133, 1)" />
                            <span className={styles.adjustInputText}>Compare with Work</span>
                        </div>
                    </>
            }
            {(approach == Approaches.ReadRetrieveRead && chatMode == ChatMode.WorkPlusWeb) &&
                    <>
                        <div className={styles.adjustInput} onClick={onWebSearchClicked} tabIndex={tabIndex}>
                            <Globe16Filled primaryFill="rgba(133, 133, 133, 1)" />
                            <span className={styles.adjustInputText}>Search Web</span>
                        </div>
                        <div className={styles.adjustInput} onClick={onWebCompareClicked} tabIndex={tabIndex}>
                            <Globe16Filled primaryFill="rgba(133, 133, 133, 1)" />
                            <span className={styles.adjustInputText}>Compare with Web</span>
                        </div>
                    </>
            }
        </div>
    );
};