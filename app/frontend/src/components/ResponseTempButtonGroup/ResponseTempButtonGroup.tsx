// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import { Button, ButtonGroup } from "react-bootstrap";
import { Label } from "@fluentui/react";

import styles from "./ResponseTempButtonGroup.module.css";

interface Props {
    className?: string;
    onClick: (_ev: any) => void;
    defaultValue?: number;
}

export const ResponseTempButtonGroup = ({ className, onClick, defaultValue }: Props) => {
    return (
        <div className={`${styles.container} ${className ?? ""}`}>
            <Label>Conversation Type:</Label>
            <ButtonGroup className={`${styles.buttongroup ?? ""}`} onClick={onClick}>
                <Button className={`${defaultValue == 1.0? styles.buttonleftactive : styles.buttonleft ?? ""}`} size="sm" value={1.0} bsPrefix='ia'>{"Creative"}</Button>
                <Button className={`${defaultValue == 0.6? styles.buttonmiddleactive : styles.buttonmiddle ?? ""}`} size="sm" value={0.6} bsPrefix='ia'>{"Balanced"}</Button>
                <Button className={`${defaultValue == 0? styles.buttonrightactive : styles.buttonright ?? ""}`} size="sm" value={0} bsPrefix='ia'>{"Precise"}</Button>
            </ButtonGroup>
        </div>
    );
};