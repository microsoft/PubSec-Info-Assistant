// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import { BuildingMultiple24Filled, Globe24Filled, Link20Filled, Sparkle24Filled } from "@fluentui/react-icons";
import { Approaches } from "../../api";

import styles from "./Answer.module.css";

interface AnswerIconProps {
    approach: Approaches;
}

export const AnswerIcon: React.FC<AnswerIconProps> = ({ approach }) => {
    if (approach == Approaches.ChatWebRetrieveRead) {
        return <div className={styles.answerLogoWeb}><Globe24Filled primaryFill={"rgba(24, 141, 69, 1)"} aria-hidden="true" aria-label="Web Answer logo" /> Web</div>;
        }
    else if (approach == Approaches.ReadRetrieveRead) {
        return <div className={styles.answerLogoWork}><BuildingMultiple24Filled primaryFill={"rgba(27, 74, 239, 1)"} aria-hidden="true" aria-label="Work Answer logo" /> Work</div>;
        }
    else if (approach == Approaches.CompareWebWithWork) {
        return <div className={styles.answerLogoCompare}><Globe24Filled primaryFill={"rgba(206, 123, 46, 1)"} aria-hidden="true" aria-label="Web Compared to Work Answer Logo" /><Link20Filled primaryFill={"rgba(206, 123, 46, 1)"} /><BuildingMultiple24Filled primaryFill={"rgba(206, 123, 46, 1)"} aria-hidden="true" /> Web compared to Work</div>;
        }
    else if (approach == Approaches.CompareWorkWithWeb) {
        return <div className={styles.answerLogoCompare}><BuildingMultiple24Filled primaryFill={"rgba(206, 123, 46, 1)"} aria-hidden="true" aria-label="Work Compared to Web Answer logo" /><Link20Filled primaryFill={"rgba(206, 123, 46, 1)"} /><Globe24Filled primaryFill={"rgba(206, 123, 46, 1)"} aria-hidden="true" /> Work compared to Web</div>;
        }
    else {
        return <div className={styles.answerLogoUngrounded}><Sparkle24Filled primaryFill={"rgba(0, 0, 0, 1)"}/><div className={styles.answerLogoUngroundedText}>Information Assistant</div></div>;
    }
};
