import { Example } from "./Example";

import styles from "./Example.module.css";

export type ExampleModel = {
    text: string;
    value: string;
};

const EXAMPLES: ExampleModel[] = [
    {
        text: "Do we have any images of an airplane with a tailsign of Z-102?",
        value: "Do we have any images of an airplane with a tailsign of Z-102?"
    },
    { text: "What services does Toyota provide to the defense industry?", value: "What services does Toyota provide to the defense industry?" },
    { text: "Compare the destroyers of the US Navy and the Chinese Navy.", value: "Compare the destroyers of the US Navy and the Chinese Navy." }
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
