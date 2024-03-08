// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import { Sparkle28Filled } from "@fluentui/react-icons";
import { Icon } from "@fluentui/react";

interface AnswerIconProps {
    source?: string;
}

export const AnswerIcon: React.FC<AnswerIconProps> = ({ source }) => {
    if (source === 'bing') {
        return <Icon iconName="BingLogo" aria-hidden="true" aria-label="Bing logo" styles={{ root: { fontSize: '30px' } }}/>;
    }
    return <Sparkle28Filled primaryFill={"rgba(115, 118, 225, 1)"} aria-hidden="true" aria-label="Answer logo" />;
};
