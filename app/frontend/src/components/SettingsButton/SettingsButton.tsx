// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import { Text } from "@fluentui/react";
import { Options24Filled } from "@fluentui/react-icons";

import styles from "./SettingsButton.module.css";

interface Props {
    className?: string;
    onClick: () => void;
}

export const SettingsButton = ({ className, onClick }: Props) => {
    return (
        <div className={`${styles.container} ${className ?? ""}`} onClick={onClick}>
            <Options24Filled />
            <Text>{"Adjust"}</Text>
        </div>
    );
};
