// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import { Icon } from '@fluentui/react';
import styles from "./UserChatMessage.module.css";

interface Props {
    message: string;
    iconName?: string;
}

export const UserChatMessage = ({ message, iconName }: Props) => {
    return (
        <div className={styles.container}>
            <div className={styles.message}>
                {iconName && <span style={{ marginRight: '10px' }}><Icon iconName={iconName} /></span>}
                <span>{message}</span>
            </div>
        </div>
    );
};
