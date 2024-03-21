// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import { Button, ButtonGroup } from "react-bootstrap";
import { ChatMode } from "../../api";

import styles from "./ChatModeButtonGroup.module.css";

interface Props {
    className?: string;
    onClick: (_ev: any) => void;
    defaultValue?: ChatMode;
}

export const ChatModeButtonGroup = ({ className, onClick, defaultValue }: Props) => {
    return (
        <div className={`${styles.container} ${className ?? ""}`}>
            <ButtonGroup className={`${styles.buttonGroup}`} onClick={onClick} bsPrefix="ia">
                <Button className={`${defaultValue == ChatMode.WorkOnly? styles.buttonleftactive : styles.buttonleft ?? ""}`} size="sm" value={0} bsPrefix='ia'>{"Work Only"}</Button>
                <Button className={`${defaultValue == ChatMode.WorkPlusWeb? styles.buttonmiddleactive : styles.buttonmiddle ?? ""}`} size="sm" value={1} bsPrefix='ia'>{"Work + Web"}</Button>
                <Button className={`${defaultValue == ChatMode.Ungrounded? styles.buttonrightactive : styles.buttonright ?? ""}`} size="sm" value={2} bsPrefix='ia'>{"Generative (Ungrounded)"}</Button>
            </ButtonGroup>
        </div>
    );
};