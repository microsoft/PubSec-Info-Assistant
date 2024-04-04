// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import { Example } from "./Example";

import styles from "./Example.module.css";

export type ExampleModel = {
    text: string;
    value: string;
};

const EXAMPLES: ExampleModel[] = [
    { text: "How do I create a tickler in the CAREweb system?", value: "How do I create a tickler in the CAREweb system?" },
    { text: "Where can I find RMT or Electronic Signature resources?", value: "Where can I find RMT or Electronic Signature resources?" },
    { text: "How do I add a guardian in PDS?", value: "How do I add a guardian in PDS?" },
    { text: "What training is required for CRMs?", value: "What training is required for CRMs?" }
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
