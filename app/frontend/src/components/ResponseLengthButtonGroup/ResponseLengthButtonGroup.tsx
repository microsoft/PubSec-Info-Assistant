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
            <Label>Response length:</Label>
            <ButtonGroup className={`${styles.buttongroup ?? ""}`} onClick={onClick}>
                <Button id="Succinct" className={`${defaultValue == 1024? styles.buttonleftactive : styles.buttonleft ?? ""}`} size="sm" value={1024}>{"Succinct"}</Button>
                <Button id="Standard" className={`${defaultValue == 2048? styles.buttonmiddleactive : styles.buttonmiddle ?? ""}`} size="sm" value={2048}>{"Standard"}</Button>
                <Button id="Thorough" className={`${defaultValue == 4096? styles.buttonrightactive : styles.buttonright ?? ""}`} size="sm" value={4096}>{"Thorough"}</Button>
            </ButtonGroup>
        </div>
    );
};