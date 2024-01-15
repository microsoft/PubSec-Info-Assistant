// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import { Example } from "./Example";

import styles from "./Example.module.css";

export type ExampleModel = {
    text: string;
    value: string;
};

const EXAMPLES: ExampleModel[] = [
    { text: "What are the steps I need to take to discontinue a case?", value: "What are the steps I need to take to discontinue a case?" },
    { text: "What systems are required for issuing a discontinuance?", value: "What systems are required for issuing a discontinuance?" },
    { text: "What do I need to do if there are co-defendants?", value: "What do I need to do if there are co-defendants?" }
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
