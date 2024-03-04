// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import { Options16Filled, ArrowSync16Filled, DatabaseStack16Filled } from "@fluentui/react-icons";

import styles from "./RAIPanel.module.css";
import { Icon } from "@fluentui/react";

interface Props {
    source?: string;
    comparative?: boolean;
    onAdjustClick?: () => void;
    onRegenerateClick?: () => void;
    onBingSearchClicked?: () => void;
    onRagSearchClicked?: () => void;
    onBingCompareClicked?: () => void;
    onRagCompareClicked?: () => void;
}

export const RAIPanel = ({ source, comparative, onAdjustClick, onRegenerateClick, onBingSearchClicked, onRagSearchClicked, onBingCompareClicked, onRagCompareClicked }: Props) => {
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
            {!comparative && (
                source === 'bing' ? (
                    <>
                        <div className={styles.adjustInput} onClick={onRagSearchClicked}>
                            <DatabaseStack16Filled primaryFill="rgba(133, 133, 133, 1)" />
                            <span className={styles.adjustInputText}>Search Data</span>
                        </div>
                        <div className={styles.adjustInput} onClick={onRagCompareClicked}>
                            <DatabaseStack16Filled primaryFill="rgba(133, 133, 133, 1)" />
                            <span className={styles.adjustInputText}>Compare Data</span>
                        </div>
                    </>
                ) : (
                    <>
                        <div className={styles.adjustInput} onClick={onBingSearchClicked}>
                            <Icon iconName={"BingLogo"} />
                            <span className={styles.adjustInputText}>Search Bing</span>
                        </div>
                        <div className={styles.adjustInput} onClick={onBingCompareClicked}>
                            <Icon iconName={"BingLogo"} />
                            <span className={styles.adjustInputText}>Compare Bing</span>
                        </div>
                    </>
                )
            )}
        </div>
    );
};