define [
	"main/project-list/index"
	"main/user-details"
	"main/account-settings"
	"main/account-upgrade"
	"main/templates"
	"main/plans"
	"main/group-members"
	"main/scribtex-popup"
	"main/event"
	"main/bonus"
	"main/system-messages"
	"main/translations"
	"main/subscription-dashboard"
	"main/new-subscription"
	"main/annual-upgrade"
	"main/register-users"
	"analytics/AbTestingManager"
	"directives/asyncForm"
	"directives/stopPropagation"
	"directives/focus"
	"directives/equals"
	"directives/fineUpload"
	"directives/onEnter"
	"directives/selectAll"
	"directives/maxHeight"
	"filters/formatDate"
	"__MAIN_CLIENTSIDE_INCLUDES__"
], () ->
	angular.bootstrap(document.body, ["SharelatexApp"])
