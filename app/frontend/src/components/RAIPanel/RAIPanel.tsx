// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import { Options16Filled } from "@fluentui/react-icons";

import styles from "./RAIPanel.module.css";

interface Props {
    onAdjustClick?: () => void;
}

export const RAIPanel = ({ onAdjustClick }: Props) => {

    return (
        <div className={styles.adjustInput} onClick={onAdjustClick}>
            <Options16Filled primaryFill="rgba(133, 133, 133, 1)" />
            <span className={styles.adjustInputText}>Adjust</span>
        </div>
    );
};