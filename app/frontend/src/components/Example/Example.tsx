// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import React, { useRef, useEffect } from "react";
import styles from "./Example.module.css";

interface Props {
    text: string;
    value: string;
    onClick: (value: string) => void;
    tabIndex: number;
}

export const Example = ({ text, value, onClick, tabIndex }: Props) => {
    const buttonRef = useRef<HTMLDivElement>(null);

    const handleKeyDown = (e: KeyboardEvent) => {
        if (e.key === " " || e.key === "Enter" || e.key === "Spacebar") {
            onClick(value);
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
    }, [value, onClick]);

    return (
        <div
            ref={buttonRef}
            tabIndex={tabIndex}
            className={styles.example}
            onClick={() => onClick(value)}
            role="button"
        >
            <p className={styles.exampleText}>{text}</p>
        </div>
    );
};
