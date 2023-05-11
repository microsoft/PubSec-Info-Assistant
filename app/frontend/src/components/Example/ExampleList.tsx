import { Example } from "./Example";

import styles from "./Example.module.css";

export type ExampleModel = {
    text: string;
    value: string;
};

const EXAMPLES: ExampleModel[] = [
    { text: "What impact does China have on climate change?", value: "What impact does China have on climate change?" },
    { text: "What are Microsoft's primary sources of revenue?", value: "What are Microsoft's primary sources of revenue?" },
    { text: "Provide a report comparing the Arleigh Burke destroyers with the Chinese Type 055.", value: "Provide a report comparing the Arleigh Burke destroyers with the Chinese Type 055." }
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
