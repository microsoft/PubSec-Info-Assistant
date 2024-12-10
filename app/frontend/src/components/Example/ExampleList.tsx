// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import { Example } from "./Example";

import styles from "./Example.module.css";

export type ExampleModel = {
    text: string;
    value: string;
};


const EXAMPLES: ExampleModel[] = [
    { text: "What is health services quota?", value: "What is health services quota?" },
    { text: "Would there be no limit in terms of privileges under the plan?", value: "Would there be no limit in terms of privileges under the plan?" },
    { text: "Who are covered by the mandatory AME?", value: "Who are covered by the mandatory AME?" }
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
