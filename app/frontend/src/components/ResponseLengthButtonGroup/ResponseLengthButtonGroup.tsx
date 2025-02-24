// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import { Button, ButtonGroup } from "react-bootstrap";
import { Label } from "@fluentui/react";

import styles from "./ResponseLengthButtonGroup.module.css";

interface Props {
    className?: string;
    onClick: (_ev: any) => void;
    defaultValue?: number;
}

export const ResponseLengthButtonGroup = ({ className, onClick, defaultValue }: Props) => {
    return (
        <div className={`${styles.container} ${className ?? ""}`}>
            <Label id="responseLengthLabel">Response length:</Label>
            <ButtonGroup className={`${styles.buttongroup ?? ""}`} onClick={onClick}>
                <Button id="Succinct" aria-labelledby="responseLengthLabel Succinct" className={`${defaultValue == 1024? styles.buttonleftactive : styles.buttonleft ?? ""}`} size="sm" value={1024} bsPrefix='ia'>{"Succinct"}</Button>
                <Button id="Standard" aria-labelledby="responseLengthLabel Standard" className={`${defaultValue == 2048? styles.buttonmiddleactive : styles.buttonmiddle ?? ""}`} size="sm" value={2048} bsPrefix='ia'>{"Standard"}</Button>
                <Button id="Thorough" aria-labelledby="responseLengthLabel Thorough" className={`${defaultValue == 3072? styles.buttonrightactive : styles.buttonright ?? ""}`} size="sm" value={3072} bsPrefix='ia'>{"Thorough"}</Button>
            </ButtonGroup>
        </div>
    );
};
