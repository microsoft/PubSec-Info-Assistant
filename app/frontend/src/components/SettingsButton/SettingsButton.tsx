// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import { Text } from "@fluentui/react";
import { Options24Filled } from "@fluentui/react-icons";
import React, { useEffect, useRef } from 'react';


import styles from "./SettingsButton.module.css";

interface Props {
    className?: string;
    onClick: () => void;
}

export const SettingsButton = ({ className, onClick }: Props) => {
    const buttonRef = useRef<HTMLDivElement>(null);

    const handleKeyDown = (e: KeyboardEvent) => {
        if (e.key === " " || e.key === "Enter" || e.key === "Spacebar") {
            onClick();
        }
    };

    useEffect(() => {
        const button = buttonRef.current;
        if (button) {
            button.addEventListener('keydown', handleKeyDown);
        }
        return () => {
            if (button) {
                button.removeEventListener('keydown', handleKeyDown);
            }
        };
    }, []);
    return (
        <div role="button" ref={buttonRef} className={`${styles.container} ${className ?? ""}`} onClick={onClick} tabIndex={0}>
            <Options24Filled className={styles.icon} />
            <Text className={styles.text} >{"Adjust"}</Text>
        </div>
    );
};
