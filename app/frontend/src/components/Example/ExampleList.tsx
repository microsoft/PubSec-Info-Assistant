// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import { Example } from "./Example";

import styles from "./Example.module.css";

export type ExampleModel = {
    text: string;
    value: string;
};

const EXAMPLES: ExampleModel[] = [
    { text: "What is the process for submitting travel expenses for reimbursement?", value: "What is the process for submitting travel expenses for reimbursement?" },
    { text: "What are the guidelines for publishing content on social media platforms?", value: "What are the guidelines for publishing content on social media platforms?" },
    { text: "What projects were executed during COVID-19?", value: "What projects were executed during COVID-19?" }
];

interface Props {
    onExampleClicked: (value: string) => void;
}

export const ExampleList = ({ onExampleClicked }: Props) => {
    return (
        <ul className={styles.examplesNavList}>
            {EXAMPLES.map((x, i) => (
                <li key={i}>
                    <Example text={x.text} value={x.value} onClick={onExampleClicked} />
                </li>
            ))}
        </ul>
    );
};
