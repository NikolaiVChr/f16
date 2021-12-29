/* globals utils, gitHubInjection, pageDetect */

'use strict';

function sortIssues() {
	const issuesTab = document.querySelector('.reponav-item[href$="issues"');
	if (issuesTab) {
		issuesTab.href += '?q=is%3Aissue+is%3Aopen+sort%3Aupdated-desc';
	}
}

document.addEventListener('DOMContentLoaded', () => {
	const username = getUsername();

	if (pageDetect.isRepo()) {
		gitHubInjection(window, () => {
			sortIssues();
		});
	}
});