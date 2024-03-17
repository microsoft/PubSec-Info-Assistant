// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import { Text } from "@fluentui/react";
import { Chat12Regular } from "@fluentui/react-icons";
import styles from "./ChatButton.module.css";

interface Props {
    className?: string;
    onClick: () => void;
}

export const ChatButton = ({ className, onClick }: Props) => {
    return (
        <div className={`${styles.container} ${className ?? ""}`} onClick={onClick}>
            <Chat12Regular />
            <Text>{"Chat"}</Text>
        </div>
    );
};
