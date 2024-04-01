// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import { useRef, useState, useEffect } from "react";
import { Panel, DefaultButton} from "@fluentui/react";
import styles from "./Layout.module.css";
import { ChatButton } from "../../components/ChatButton";
import { ModalChat } from "../../components/ModalChat";

const Layout = () => {
    const [isInfoPanelOpen, setIsInfoPanelOpen] = useState(false);
    return (
        <div className={styles.layout}>
            <div className={styles.chatButton}>
                <ChatButton className={styles.commandButton} onClick={() => setIsInfoPanelOpen(!isInfoPanelOpen)} />
            </div>
            <Panel
                headerText="Modal Chat"
                isOpen={isInfoPanelOpen}
                isBlocking={false}
                onDismiss={() => setIsInfoPanelOpen(false)}
                closeButtonAriaLabel="Close"
                className={styles.modalchatpanel}
                onRenderFooterContent={() => <DefaultButton onClick={() => setIsInfoPanelOpen(false)}>Close</DefaultButton>}
                isFooterAtBottom={true}                >
                    <div id="modalChatMain">
                        <ModalChat/>
                    </div>
            </Panel>
        </div>
    );
};

export default Layout;
