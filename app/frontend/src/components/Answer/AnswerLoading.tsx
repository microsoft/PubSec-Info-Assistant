// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import { Stack } from "@fluentui/react";
import { animated, useSpring } from "@react-spring/web";

import styles from "./Answer.module.css";
import { AnswerIcon } from "./AnswerIcon";
import { Approaches } from "../../api";

interface AnswerLoadingProps {
    approach: Approaches;
}

export const AnswerLoading: React.FC<AnswerLoadingProps> = ({ approach }) => {
    const animatedStyles = useSpring({
        from: { opacity: 0 },
        to: { opacity: 1 }
    });

    return (
        <animated.div style={{ ...animatedStyles }}>
            <Stack className={approach == Approaches.GPTDirect ? styles.answerContainerUngrounded : styles.answerContainer} verticalAlign="space-between">
                <AnswerIcon approach={approach}/>
                <Stack.Item grow>
                    <p className={approach == Approaches.GPTDirect ? styles.answerTextUngrounded : styles.answerText}>
                        Generating answer
                        <span className={styles.loadingdots} />
                    </p>
                </Stack.Item>
            </Stack>
        </animated.div>
    );
};
