//= require jquery
//= require jquery-ui/widgets/datepicker
//= require jquery-ui/i18n/datepicker-fr-CH
//= require jquery-ui/i18n/datepicker-de
//= require turbolinks

var selectDate = function selectDate(dateText) {
  $('.no_halfdays').hide();
  $('.halfdays label').hide();
  $('#subscribe-button').prop('disabled', false);
  $('.halfdays input').prop('checked', false);
  $('label.halfday-' + dateText).show();
  $('label.halfday-' + dateText + ' input:enabled:first').prop('checked', true);
  if (!$('label.halfday-' + dateText + ' input:enabled').length) {
    $('#subscribe-button').prop('disabled', true);
  }
};

var setupDatepicker = function setupDatepicker() {
  var dateTexts = $('#datepicker').data('dates');
  if (dateTexts) {
    var minDateText = dateTexts[0],
      maxDateText = dateTexts[dateTexts.length - 1];
    var selectedDateText = $('#datepicker').data('selected-date') || minDateText;
    selectDate(selectedDateText);

    $('#datepicker').datepicker({
      dateFormat: 'yy-mm-dd',
      firstDay: 1,
      minDate: minDateText,
      maxDate: maxDateText,
      defaultDate: selectedDateText,
      // onSelect: function onSelect(dateText, inst) {
      //   selectDate(dateText);
      // },
      // beforeShowDay: function beforeShowDay(date) {
      //   var dateText = $.datepicker.formatDate('yy-mm-dd', date);
      //   if (dateTexts.includes(dateText)) {
      //     return [true, 'available', null];
      //   } else {
      //     return [false, null, null];
      //   }
      // },
      onChangeMonthYear: function onChangeMonthYear(year, month) {
        var dateText = dateTexts.filter(function(d) {
          var dd = new Date(d);
          return dd.getFullYear() === year && dd.getMonth() + 1 === month;
        })[0];
        if (dateText) {
          $('#datepicker').datepicker('setDate', dateText);
          selectDate(dateText);
        } else {
          $('.no_halfdays').show();
          $('.halfdays label').hide();
          $('#subscribe-button').prop('disabled', true);
          $('.halfdays input').prop('checked', false);
        }
      }
    });
  }
};

$(function() {
  document.addEventListener('turbolinks:load', function() {
    setupDatepicker();
  });
});
