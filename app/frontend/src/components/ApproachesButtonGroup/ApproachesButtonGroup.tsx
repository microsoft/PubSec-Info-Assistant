// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import { Button, ButtonGroup } from "react-bootstrap";
import { Label } from "@fluentui/react";

import styles from "./ApproachesButtonGroup.module.css";
import {Approaches} from "../../api";

interface Props {
    className?: string;
    onClick: (_ev: any) => void;
    defaultValue?: number;
}

export const ApproachesButtonGroup = ({ className, onClick, defaultValue }: Props) => {
    return (
        <div className={`${styles.container} ${className ?? ""}`}>
            <Label>Data Source Grounding:</Label>
            <ButtonGroup className={`${styles.buttongroup ?? ""}`} onClick={onClick}>
                <Button id={Approaches.ReadRetrieveRead.toString()} className={`${defaultValue == Approaches.ReadRetrieveRead? styles.buttonleftactive : styles.buttonleft ?? ""}`} size="sm" value={Approaches.ReadRetrieveRead} bsPrefix='ia'>{"Chat with Grounding"}</Button>
                <Button id={Approaches.GPTDirect.toString()} className={`${defaultValue == Approaches.GPTDirect? styles.buttonrightactive : styles.buttonmiddle ?? ""}`} size="sm" value={Approaches.GPTDirect}bsPrefix='ia'>{"Chat with GPT Directly"}</Button>
            </ButtonGroup>
        </div>
    );
};
