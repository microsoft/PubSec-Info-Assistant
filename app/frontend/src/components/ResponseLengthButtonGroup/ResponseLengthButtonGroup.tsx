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
        <div className={`${styles.container}`}>
            {/* <Label>Response length:</Label> */}
            <ButtonGroup className={`${styles.buttonGroup ?? ""}`} onClick={onClick} bsPrefix="ia">
                <Button id="Succinct" className={`${defaultValue == 1024? styles.buttonleftactive : styles.buttonleft ?? ""}`} size="sm" value={1024} bsPrefix='ia'>{"Succinct Response"}</Button>
                <Button id="Standard" className={`${defaultValue == 2048? styles.buttonmiddleactive : styles.buttonmiddle ?? ""}`} size="sm" value={2048} bsPrefix='ia'>{"Standard Response"}</Button>
                <Button id="Thorough" className={`${defaultValue == 3072? styles.buttonrightactive : styles.buttonright ?? ""}`} size="sm" value={3072} bsPrefix='ia'>{"Thorough Response"}</Button>
            </ButtonGroup>
        </div>
    );
};
