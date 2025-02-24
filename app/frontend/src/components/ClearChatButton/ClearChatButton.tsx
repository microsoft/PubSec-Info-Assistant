// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import { Text } from "@fluentui/react";
import { ChatAddRegular  } from "@fluentui/react-icons";

import styles from "./ClearChatButton.module.css";

interface Props {
    className?: string;
    onClick: () => void;
    disabled?: boolean;
}

export const ClearChatButton = ({ className, disabled, onClick }: Props) => {
    return (
        <div className={`${styles.container} ${className ?? ""} ${disabled && styles.disabled}`} onClick={onClick} role="button" tabIndex={0}>
            <ChatAddRegular  className={styles.icon} />
            <Text className={styles.text} style={{ color: '#6b6b6a' }}>{"New chat"}</Text>
        </div>
    );
};
