// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import { Options16Filled, ArrowSync16Filled } from "@fluentui/react-icons";

import styles from "./RAIPanel.module.css";

interface Props {
    onAdjustClick?: () => void;
    onRegenerateClick?: () => void;
}

export const RAIPanel = ({ onAdjustClick, onRegenerateClick }: Props) => {

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
        </div>
    );
};