// This should be set as a rule that matches *.slack.com.
// The rule should use this script and target the Slack app
(function() {
    const url = ctx.url;
    const workspaceLookup = {
        'temporaltechnologies': 'TT31S6VK5'
    };

    try {
        url.protocol = 'slack';

        // Extract workspace name from the URL host
        const workspaceName = url.hostname.split('.')[0];
        const teamId = workspaceLookup[workspaceName];
        console.log("workspace:" + workspaceName);

        if (!teamId) {
            throw new Error(`Workspace ${workspaceName} not found in lookup.`);
        }

        // Extract Channel ID and Timestamp from the URL path
        const pathSegments = url.pathname.split('/');
        const channelId = pathSegments[2];
        const raw = pathSegments[3].replace('p', '');
        const timestamp = raw.slice(0, 10) + '.' + raw.slice(10);

        // Update the URL with new format (remove hostname)
        url.hostname = 'channel'; // Remove the workspace hostname
        url.pathname = '';
        url.searchParams.set('team', teamId);
        url.searchParams.set('id', channelId);
        url.searchParams.set('message', timestamp);

    } catch (error) {
        console.log(`Error converting URL: ${error.message}`);
    }
})();
