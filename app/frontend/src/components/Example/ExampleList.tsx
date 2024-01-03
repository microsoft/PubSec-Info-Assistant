// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import { Example } from "./Example";

import styles from "./Example.module.css";

export type ExampleModel = {
    text: string;
    value: string;
};

const EXAMPLES: ExampleModel[] = [
    { text: "What was the total income in 2022 for the Brompton's Children Centre?", value: "What was the total income in 2022 for the Brompton's Children Centre?" },
    { text: "Who are the Directors of New Haven Farm Home", value: "Who are the Directors of New Haven Farm Home" },
    { text: "Does the Clarendon Children's Home report have a signed auditor's report?", value: "Does the Clarendon Children's Home report have a signed auditor's report?" }
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
