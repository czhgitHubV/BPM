<%@ Page Language="C#" AutoEventWireup="true" CodeFile="LeaveRequestMsr.aspx.cs" Inherits="OThinker.H3.Portal.Sheets.DefaultEngine.LeaveRequestMsr" EnableEventValidation="false" MasterPageFile="~/MvcSheet.master" %>

<%@ OutputCache Duration="100" VaryByParam="T" VaryByCustom="browser" %>
<asp:Content ID="head" ContentPlaceHolderID="headContent" runat="Server">
    <link href="JavaScripts/sheetContent.css" rel="stylesheet" />
    <script src="JavaScripts/UserSelect.js?170101002"></script>
    <script src="JavaScripts/adddate/adddate.js"></script>
    <style>

    </style>
    <script type="text/javascript">
        var rows = 1;
        //#region 从后台获取年假信息
        function GetALData(datarow) {
            if (datarow > 0) {
                var user = $.MvcSheetUI.GetControlValue("LeaveRequestDtl.LRD_Applicant", datarow);
                var typeUI = $.MvcSheetUI.GetElement("LeaveRequestDtl.LRD_Type", datarow).SheetUIManager();;
                var type = typeUI.GetValue();
                var typeStr = typeUI.GetText();
                var info = $('.al_info').get(datarow);
                //修改请假单位 只有调休可以请小时
                $.MvcSheetUI.SetControlValue("LeaveRequestDtl.LRD_Uom", type == "DaysOff" ? "小时" : "天", datarow)
                //香港同事不显示
                if (user.substring(0, 2) == 'HK') {
                    $(info).hide();
                    return;
                }
                if (!ValidateDateHours(datarow)) {
                    return;
                }
                if (user == '' || !(type == 'AnnualLeave' || type == 'DaysOff')) {
                    $(info).hide();
                    return;
                }

                var unit = type == "DaysOff" ? "小时" : "天";
                var url = type == "AnnualLeave" ? "GetALData" : "GetDaysOffData";
                $.MvcSheet.Action(
                      {
                          Action: url,   // 后台方法名称
                          Datas: [user],    // 输入参数，格式 ["{数据项名称}","String值","控件ID"]，当包含数据项名称时 LoadControlValue必须为true
                          async: true,
                          LoadControlValue: false, // 是否获取表单数据
                          PostSheetInfo: false,    // 是否获取已经改变的表单数据
                          OnActionDone: function (e) {
                              // 执行完成后回调事件
                              if (e) {
                                  $(info).html("剩" + typeStr + e + unit);
                                  $(info).attr('class', 'label al_info label-success');
                                  $(info).show();
                              }
                              else {
                                  $(info).html("无信息");
                                  $(info).attr('class', 'label al_info label-warning');
                                  $(info).show();
                              }
                          }
                      })
            }
        }
        //#endregion
        //#region初始化显示
        $.MvcSheet.Loaded = function (sheetInfo) {
            var activityCode = $.MvcSheetUI.SheetInfo.ActivityCode; //当前活动节点
            var dept = sheetInfo.OriginatorOU;
            //修改下拉框只显示所选择部门人员
            if (activityCode == "Activity2") {
                var childTable = $.MvcSheetUI.GetElement("LeaveRequestDtl").SheetGridView();
                if (childTable) {
                    childTable.OnAdded = function (e, val, rowcount) {
                        //var deptID = $.MvcSheetUI.GetControlValue('LRM_ApplyOrg');
                        //var row = $("table[data-datafield='LeaveRequestDtl']").find("tr.rows").length;
                        ////处理人员
                        //var sheetUser = $.MvcSheetUI.GetElement("LeaveRequestDtl.LRD_Applicant", row).SheetUIManager();
                        //if (sheetUser) {
                        //    sheetUser.SetRootUnit(deptID);
                        //    sheetUser.Render();
                        //}
                        //处理默认请假单位
                        //$.MvcSheetUI.SetControlValue("LeaveRequestDtl.LRD_Uom", "天", rowcount + 1)
                        inituserSelect(dept);
                        $('#modalBtn').click();
                        rows = rowcount + 1;
                        
                    }
                }
                //GetDeptUsers();
            }
            //
            inituserSelect(dept);
            //修改部门为只读
            $("[data-datafield='Originator.OUName']").children().attr("disabled", "disabled");
            //显示考勤打卡记录,隐藏删除/增加按钮，只有人事的时候通过该功能隐藏，因为人事有明细数据的修改权限
            if (activityCode == "Activity10") {
                $(".record").removeClass('hidden');
                $(".rowOption").hide();
                $.MvcSheetUI.GetElement("LeaveRequestDtl").SheetGridView().addbtn.hide();

                //获取调休不够的信息
                $.MvcSheet.Action({
                    Action: "GetValidateDaysOff", // 执行后台方法名称
                    Datas: [$.MvcSheetUI.SheetInfo.BizObjectID],
                    LoadControlValue: false, // 输入参数，格式 ["{数据项名称}","String值","控件ID"]，当包含数据项名称时 LoadControlValue必须为true
                    PostSheetInfo: false, //是否获取已经改变的表单数据
                    OnActionDone: function (e) {
                        if (e != null && typeof (e) != "undefined") {
                            $(".hidVal").val(e);
                        }
                    }
                });

            }
            GetReord();
            $("table[data-datafield='LeaveRequestDtl']").find("tr.rows").each(function () {
                var datarow = $(this).attr("data-row");
                GetALData(datarow);
            });
            //修改只显示当前部门
            //var deptID = $.MvcSheetUI.GetControlValue('LRM_ApplyOrg');
            //var sheet = $.MvcSheetUI.GetElement("LRM_ApplyOrg").SheetUIManager();
            //if (sheet) {
            //    sheet.SetRootUnit(sheet.GetValue());//该函数有bug，第一次调用会出错。不能在后面写处理语句
            //    sheet.Render();
            //}
            selectShift();
        }
        //#endregion
        //#region初始化人员选择插件
        function inituserSelect(deptNo) {
            var s = $("input[data-datafield='LeaveRequestDtl.LRD_Applicant']");
            if (s.length > 0) {
                s.userSelect({
                    mapping: "LeaveRequestDtl.LRD_Applicant:Code,LeaveRequestDtl.LRD_ApplicantName:Name",
                    postpara: '[{"Dept": "' + deptNo + '","Site":"GZ"}]'//需要传递的其他参数
                });
            }
        }
        //#endregion
        //#region从后台获取考勤数据
        function GetReord() {
            $("table[data-datafield='LeaveRequestDtl']").find("tr.rows").each(function () {
                var datarow = $(this).attr("data-row");
                var Applicant = $.MvcSheetUI.GetControlValue("LeaveRequestDtl.LRD_Applicant", datarow);
                var StartTime = $.MvcSheetUI.GetControlValue("LeaveRequestDtl.LRD_StartTime", datarow);
                var EndTime = $.MvcSheetUI.GetControlValue("LeaveRequestDtl.LRD_EndTime", datarow);
                var row = $(this);
                //获取考勤记录
                $.MvcSheet.Action({
                    Action: "GetRecordsCheck", // 执行后台方法名称
                    Datas: [Applicant, StartTime, EndTime],
                    LoadControlValue: false, // 输入参数，格式 ["{数据项名称}","String值","控件ID"]，当包含数据项名称时 LoadControlValue必须为true
                    PostSheetInfo: false, //是否获取已经改变的表单数据
                    OnActionDone: function (e) {
                        if (e != null && typeof (e) != "undefined") {
                            var tr = "";
                            for (var i = 0; i < e.length; i++) {
                                if (e[i]) {
                                    tr += "<tr><td>" + "</td><td>" + e[i].ClockTime + "</td></tr>"
                                }
                                var td = "<table class='table table-striped table-condensed'> " + tr + "</table>"
                                row.find(".recordList").html(td);
                            }
                        }
                    }
                });

                //获取调休记录
                var type = $.MvcSheetUI.GetControlValue("LeaveRequestDtl.LRD_Type", datarow);
                if (type != null && typeof (type) != "undefined" && type == "DaysOff") {
                    //获取弹窗链接
                    var src = _PORTALROOT_GLOBAL + "/Sheets/Reports/DaysOffPop.aspx?empid=" + Applicant;
                    row.find(".daysoffList").removeClass("hidden").find("a").bind("click", function () {
                        var m = new $.SheetModal("调休假剩余查询",
                            "<iframe scrolling='no' frameborder='0' width='100%' height='600px' src='" + src + "'></iframe>"
                            );
                        m.Modal.find('div.modal-dialog').width("800px");
                    });
                }
            })
        }
        //#endregion
        //#region验证表单调休时间是否够扣减 无法在验证的时候异步获取，所以加载的时候就判断出来
        $.MvcSheet.Validate = function () {
            if ($.MvcSheetUI.SheetInfo.ActivityCode == "Activity10" && this.Action == "Submit") {
                var e = $(".hidVal").val();
                if (e != null && typeof (e) != "undefined" && e.length > 0) {
                    //获取是否有不能扣减的
                    return confirm("如下人员调休假不够\n" + e + "\n确认要审核通过吗？");
                }
                return true;
            }
        }
        //#endregion
    </script>
    <script type="text/javascript">
        //#region验证开始时间
        function ValidateDateStart(datarow) {
            var Application = $.MvcSheetUI.GetControlValue("LeaveRequestDtl.LRD_Applicant", datarow)
            var StartTime = new Date($.MvcSheetUI.GetControlValue("LeaveRequestDtl.LRD_StartTime", datarow).replace(/-/g, "/"));
            var EndTime = new Date($.MvcSheetUI.GetControlValue("LeaveRequestDtl.LRD_EndTime", datarow).replace(/-/g, "/"));
            var input1 = $.MvcSheetUI.GetElement("LeaveRequestDtl.LRD_StartTime", datarow);
            if (StartTime > EndTime) {
                alert("开始时间不能大于结束时间！");
                $(input1).val("");
                return;
            } else if (EndTime.getFullYear() > 2000 && StartTime.getFullYear() > 2000 && (StartTime.getYear() != EndTime.getYear() || StartTime.getMonth() != EndTime.getMonth())) {
                alert("请假时间不能跨月，请重新选择！");
                $(input1).val("");
                return;
            }
            var IsAfter = $.MvcSheetUI.GetControlValue("LeaveRequestDtl.LRD_Additional", datarow);
            var DateTimeNow = new Date();

            if (IsAfter) {
                if (StartTime > DateTimeNow) {
                    alert("补单的开始时间要小于等于当前时间！");
                    $(input1).val("");
                    return;
                }
            }
            else {
                if (StartTime < DateTimeNow) {
                    alert("没补单的开始时间要大于等于当前时间！");
                    $(input1).val("");
                    return;
                }
            }
            if (!ValidateDateHours(datarow)) {
                return;
            }
            ValidateRangeBack(input1, datarow);
        }
        //#endregion

        //#region验证结束时间
        function ValidateDateEnd(datarow) {
            var Application = $.MvcSheetUI.GetControlValue("LeaveRequestDtl.LRD_Applicant", datarow)
            var StartTime = new Date($.MvcSheetUI.GetControlValue("LeaveRequestDtl.LRD_StartTime", datarow));
            var EndTime = new Date($.MvcSheetUI.GetControlValue("LeaveRequestDtl.LRD_EndTime", datarow));
            var input1 = $.MvcSheetUI.GetElement("LeaveRequestDtl.LRD_EndTime", datarow);
            if (StartTime > EndTime) {
                alert("结束时间不能小于开始时间！");
                $(input1).val("");
                return;
            } else if (EndTime.getFullYear() > 2000 && StartTime.getFullYear() > 2000 && (StartTime.getYear() != EndTime.getYear() || StartTime.getMonth() != EndTime.getMonth())) {
                alert("请假时间不能跨月，请重新选择！");
                $(input1).val("");
                return;
            }
            if (!ValidateDateHours(datarow)) {
                return;
            }
            ValidateRangeBack(input1, datarow);
        }
        //#endregion
        //#region验证是否补单
        function ValidateBunDan(datarow) {
            var StartTime = new Date($.MvcSheetUI.GetControlValue("LeaveRequestDtl.LRD_StartTime", datarow));
            var IsAfter = $.MvcSheetUI.GetControlValue("LeaveRequestDtl.LRD_Additional", datarow);
            var DateTimeNow = new Date();
            var input1 = $.MvcSheetUI.GetElement("LeaveRequestDtl.LRD_StartTime", datarow);
            if (IsAfter && StartTime > DateTimeNow) {
                alert("补单的开始时间要小于等于当前时间！");
                input1.val("");
                return;
            }
            if (!IsAfter && StartTime < DateTimeNow) {
                alert("正常单的开始时间不能小于当前时间！");
                input1.val("");
            }
        }
        //#endregion
        //#region验证请假时数
        function ValidateDateHours(datarow) {
            var Unit = $.MvcSheetUI.GetControlValue("LeaveRequestDtl.LRD_Uom", datarow);
            var Hours = parseFloat($.MvcSheetUI.GetControlValue("LeaveRequestDtl.LRD_DayNum", datarow));
            var StartTime = $.MvcSheetUI.GetControlValue("LeaveRequestDtl.LRD_StartTime", datarow);
            var EndTime = $.MvcSheetUI.GetControlValue("LeaveRequestDtl.LRD_EndTime", datarow);
            var Rang = GetDateDiff(StartTime, EndTime, Unit == '天' ? 'd' : 'h');

            if (Rang < Hours) {
                $.MvcSheetUI.SetControlValue("LeaveRequestDtl.LRD_DayNum", "", datarow);
                alert("请假数量应该小于等于开始，结束时间之差！");
                return false;
            }
            return true;
        }
        //#endregion
        //#region验证请假时间是否重复
        function ValidateRangeBack(input, datarow) {
            var application = $.MvcSheetUI.GetControlValue("LeaveRequestDtl.LRD_Applicant", datarow)
            var startstr = $.MvcSheetUI.GetControlValue("LeaveRequestDtl.LRD_StartTime", datarow);
            var endstr = $.MvcSheetUI.GetControlValue("LeaveRequestDtl.LRD_EndTime", datarow);

            if (application == null || application == "" || startstr == null || startstr == "" || endstr == null || endstr == "") { return true; };
            var starttime = new Date(startstr.replace(/-/g, "/"));
            var endTime = new Date(endstr.replace(/-/g, "/"));
            //判断当前是否有重复记录 因为系统会判断有值才能提交 所有没填完整的都不判断
            for (var i = 1; i <= $.MvcSheetUI.GetElement("LeaveRequestDtl").SheetGridView().RowCount; i++) {
                if (i == datarow) { continue };
                var app = $.MvcSheetUI.GetControlValue("LeaveRequestDtl.LRD_Applicant", i);
                var st = new Date($.MvcSheetUI.GetControlValue("LeaveRequestDtl.LRD_StartTime", i).replace(/-/g, "/"));
                var et = new Date($.MvcSheetUI.GetControlValue("LeaveRequestDtl.LRD_EndTime", i).replace(/-/g, "/"));
                if (app == null || app == "" || !st.valueOf() || !et.valueOf()) {
                    continue;
                }
                if (app == application && (!(endTime <= st || starttime >= et))) {
                    alert("该时间段在当前单重复申请，请检查！");
                    input.val("");
                    return false;
                }
            }

            //判断以往是否有重复记录
            $.MvcSheet.Action({
                Action: "CheckRange", // 执行后台方法名称
                Datas: [application, startstr, endstr],
                LoadControlValue: false, // 输入参数，格式 ["{数据项名称}","String值","控件ID"]，当包含数据项名称时 LoadControlValue必须为true
                PostSheetInfo: false, //是否获取已经改变的表单数据
                Async: false,
                OnActionDone: function (e) {
                    if (e != null && e > 0) {
                        alert("该时间段已有请假申请，不可重复申请！");
                        input.val("");
                        return false;
                    }
                }
            });
            return true;
        }


        //#endregion
        //#region申请天数限制
        // data-onchange="var row = $(this).attr('data-row');&#10;ValidateDayNo(row);"
        //function ValidateDayNo(datarow) {
        //    var isAfter = $.MvcSheetUI.GetControlValue("LeaveRequestDtl.LRD_Additional", datarow);
        //    if (!isAfter) {
        //        var startTime = new Date($.MvcSheetUI.GetControlValue("LeaveRequestDtl.LRD_StartTime", datarow));
        //        var now = new Date();
        //        var dayNo = parseFloat($.MvcSheetUI.GetControlValue("LeaveRequestDtl.LRD_DayNum", datarow));
        //        var input1 = $.MvcSheetUI.GetElement("LeaveRequestDtl.LRD_DayNum", datarow);
        //        if (dayNo <= 1 && startTime.toDateString() < now.toDateString()) {
        //            alert("请假一天内请提前一天申请");
        //            input1.val("");
        //            return;
        //        }
        //        if (dayNo > 1 && dayNo <= 7 && GetDateDiff(startTime.toDateString(), now.toDateString()) < 3) {
        //            alert("请假七天内请提前三天申请");
        //            input1.val("");
        //            return;
        //        }
        //        if (dayNo > 7 && GetDateDiff(startTime.toDateString(), now.toDateString()) < 7) {
        //            alert("请假七天以上请提前七天申请");
        //            input1.val("");
        //            return;
        //        }
        //    }
        //}
        //#endregion

        //#region修改只显示已选择部门人员
        function GetDeptUsers() {
            //var deptID = $.MvcSheetUI.GetControlValue('LRM_ApplyOrg');
            //$("table[data-datafield='LeaveRequestDtl']").find("tr.rows").each(function () {
            //    var datarow = $(this).attr("data-row");
            //    var sheetUser = $.MvcSheetUI.GetElement("LeaveRequestDtl.LRD_Applicant", datarow).SheetUser();
            //    if (sheetUser) {
            //        sheetUser.SetRootUnit(deptID);
            //        sheetUser.OrgListPanel.html("");
            //    }
            //})
        }
        //#endregion
        //#region人员改变的时候触发事件
        function GetData(e) {
            //直接得不到row行号，暂时使用该方法
            if ($(e).val().length == 0) {
                //调整名字为空
                $(e).parents("tr.rows").find("[data-datafield='LeaveRequestDtl.LRD_ApplicantName']").eq(0).val("");
            }
            var datarow = $(e).parents("tr.rows").attr("data-row");
            //判断是否有重复申请
            var Application = $.MvcSheetUI.GetControlValue("LeaveRequestDtl.LRD_Applicant", datarow)
            var StartTime = new Date($.MvcSheetUI.GetControlValue("LeaveRequestDtl.LRD_StartTime", datarow));
            var EndTime = new Date($.MvcSheetUI.GetControlValue("LeaveRequestDtl.LRD_EndTime", datarow));
            if (!ValidateRangeBack($(e), datarow)) {
                $(e).parents("tr.rows").find("[data-datafield='LeaveRequestDtl.LRD_ApplicantName']").eq(0).val("");
            };
            GetALData(datarow);

        }
        //#endregion
        //#region得到时间间隔天数
        function GetDateDiff(startDate, endDate, part) {
            var startTime = new Date(Date.parse(startDate.replace(/-/g, "/"))).getTime();
            var endTime = new Date(Date.parse(endDate.replace(/-/g, "/"))).getTime();
            var ts = Math.abs((startTime - endTime));
            switch (part) {
                case 'h'://分钟,由于没有24点，所有的加1分钟
                    return (ts / (1000 * 60 * 60)) + 0.1;
                case 'd'://天 不足一天的按八小时取整
                    return Math.ceil(ts / (1000 * 60 * 60 * 24));
                default:
                    return 0;
            }
        }
        //#endregion

        function save() {//保存退出模态框
            var holidayType = $("input[name='holType']:checked").val();
            holidayType = typeof (holidayType) == "undefined" ? "DaysOff" : holidayType;//默认假期类型为调休
            console.log(holidayType);

            $.MvcSheetUI.SetControlValue("LeaveRequestDtl.LRD_Uom", holidayType == "DaysOff" ? "小时" : "天", rows);//设置请假单位
            $.MvcSheetUI.SetControlValue("LeaveRequestDtl.LRD_Type", holidayType, rows);//设置请假类型

            if (new Date($("#startTime").val()) < new Date()) {//开始时间小于当前时间，则需要补单
                $.MvcSheetUI.SetControlValue("LeaveRequestDtl.LRD_Additional", true, rows);
            }

            $.MvcSheetUI.SetControlValue("LeaveRequestDtl.LRD_StartTime", $("#startTime").val(), rows);
            $.MvcSheetUI.SetControlValue("LeaveRequestDtl.LRD_EndTime", $("#endTime").val(), rows);

            if (holidayType == "DaysOff") {
                $.MvcSheetUI.SetControlValue("LeaveRequestDtl.LRD_DayNum", "8", rows);//设置请假天数
            } else {
                var day = new Date($("#endTime").val()).getDay() - new Date($("#startTime").val()).getDay();
                $.MvcSheetUI.SetControlValue("LeaveRequestDtl.LRD_DayNum", day + 1, rows);//设置请假天数
            }

            $('#myModal').modal('hide');
        }

            

        //设置开始和结束时间以及时间差
        //function setTime(shifts, holidayType, startTime, endTime) {
        //    var date = new Date();
        //    startDate = date.toLocaleDateString() + " " + startTime;
        //    endDate = date.toLocaleDateString() + " " + endTime;
        //    $.MvcSheetUI.SetControlValue("LeaveRequestDtl.LRD_StartTime", new Date(startDate).Format("yyyy-MM-dd hh:mm"), rows);
        //    $.MvcSheetUI.SetControlValue("LeaveRequestDtl.LRD_EndTime", new Date(endDate).Format("yyyy-MM-dd hh:mm"), rows);

        //    if (holidayType == "DaysOff") {
        //        //讲两个时间相减，求出相隔的小时
        //        $.MvcSheetUI.SetControlValue("LeaveRequestDtl.LRD_DayNum", "8", rows);
        //    } else {
        //        //讲两个时间相减，求出相隔的天数
        //        var day = new Date(endDate).getDay() - new Date(startDate).getDay();
        //        $.MvcSheetUI.SetControlValue("LeaveRequestDtl.LRD_DayNum", day + 1, rows);
        //    }
        //}

        //设置模态框中开始时间和结束时间
        function selectShift() {
            $("input[name=shift]").click(function () {

                

                var shift = $(this).val();
                var date = new Date().toLocaleDateString();
                var startTime = $("#startTime");
                var endTime = $("#endTime");

                var time1 = (new Date() + ' 00:00').toString();
                var time2 = (new Date().getDate() + ' 23:59').toString();
                console.log("kkkkkkkkkkkkk");
                console.log(time1);
                console.log(time2);
                //var timestart = new Date(Date.parse(time1.replace(/-/g, "/")));
                //var timeend = new Date(Date.parse(time2.replace(/-/g, "/")));

                //startTime.val(timestart);
                //endTime.val(timeend);

                //switch (shift) {
                //    case "normalShift": startTime.val(new Date(date).Format("yyyy-MM-dd") + " 08:30"); endTime.val(new Date(date).Format("yyyy-MM-dd") + " 17:30"); break;//正常班
                //    case "morningShift": startTime.val(new Date(date).Format("yyyy-MM-dd") + " 08:00"); endTime.val(new Date(date).Format("yyyy-MM-dd") + " 16:00"); break;//早班
                //    case "middleShift": startTime.val(new Date(date).Format("yyyy-MM-dd") + " 16:00"); endTime.val(new Date(date).Format("yyyy-MM-dd") + " 23:59"); break;//中班
                //    case "nightShift": startTime.val(new Date(date).Format("yyyy-MM-dd") + " 00:00"); endTime.val(new Date(date).Format("yyyy-MM-dd") + " 08:00"); break;//晚班
                //    default: startTime.val(new Date(date).Format("yyyy-MM-dd") + " 08:30"); endTime.val(new Date(date).Format("yyyy-MM-dd") + " 17:30");//默认为正常班
                //}
            });
        }

        //设置时间格式，fmt就是要设置的格式：如new Date(date).Format("yyyy-MM-dd")
        Date.prototype.Format = function (fmt) {
            var o = {
                "M+": this.getMonth() + 1, //月份
                "d+": this.getDate() + 1, //日
                "h+": this.getHours(), //小时 
                "m+": this.getMinutes(), //分 
                "s+": this.getSeconds(), //秒 
                "q+": Math.floor((this.getMonth() + 3) / 3), //季度 
                "S": this.getMilliseconds() //毫秒 
            };
            if (/(y+)/.test(fmt)) fmt = fmt.replace(RegExp.$1, (this.getFullYear() + "").substr(4 - RegExp.$1.length));
            for (var k in o)
                if (new RegExp("(" + k + ")").test(fmt)) fmt = fmt.replace(RegExp.$1, (RegExp.$1.length == 1) ? (o[k]) : (("00" + o[k]).substr(("" + o[k]).length)));
            return fmt;
        }
    </script>
</asp:Content>
<asp:Content ID="menu" ContentPlaceHolderID="cphMenu" runat="Server">
</asp:Content>
<asp:Content ID="master" ContentPlaceHolderID="masterContent" runat="Server">
    <label runat="server" class="hidden hidVal" />
    <div class="DragContainer" style="text-align: center;">
        <label class="panel-title" id="lblTitle">请假申请单</label>
    </div>
    <div class="panel-body sheetContainer">
        <div class="nav-icon fa fa-chevron-right bannerTitle">
            <label id="divBasicInfo" data-en_us="Basic information">基本信息</label>
        </div>
        <div class="divContent">
            <div class="row">
                <div class="col-md-2" id="divFullNameTitle">
                    <label id="lblFullNameTitle" data-type="SheetLabel" data-en_us="Originator" data-datafield="Originator.UserName" data-bindtype="OnlyVisiable">发起人</label>
                </div>
                <div class="col-md-4" id="divFullName">
                    <label id="lblFullName" data-type="SheetLabel" data-datafield="Originator.UserName" data-bindtype="OnlyData"></label>
                </div>
                <div class="col-md-2" id="divOriginateDateTitle">
                    <label id="lblOriginateDateTitle" data-type="SheetLabel" data-en_us="Originate Date" data-datafield="OriginateDate" data-bindtype="OnlyVisiable">发起时间</label>
                </div>
                <div class="col-md-4" id="divOriginateDate">
                    <label id="lblOriginateDate" data-type="SheetLabel" data-datafield="OriginateDate" data-bindtype="OnlyData"></label>
                </div>
            </div>
            <div class="row">
                <div class="col-md-2" id="divOriginateOUNameTitle">
                    <label id="lblOriginateOUNameTitle" data-type="SheetLabel" data-en_us="Originate OUName" data-datafield="Originator.OUName" data-bindtype="OnlyVisiable">所属组织</label>
                </div>
                <div class="col-md-4" id="divOriginateOUName">
                    <label id="lblOriginateOUName" data-type="SheetLabel" data-datafield="Originator.OUName" data-bindtype="OnlyData"></label>
                </div>
                <div class="col-md-2" id="divSequenceNoTitle">
                    <label id="lblSequenceNoTitle" data-type="SheetLabel" data-en_us="SequenceNo" data-datafield="SequenceNo" data-bindtype="OnlyVisiable">流水号</label>
                </div>
                <div class="col-md-4" id="divSequenceNo">
                    <label id="lblSequenceNo" data-type="SheetLabel" data-datafield="SequenceNo" data-bindtype="OnlyData"></label>
                </div>
            </div>
        </div>
        <div class="nav-icon fa  fa-chevron-right bannerTitle">
            <label id="divSheetInfo" data-en_us="Sheet information">表单信息</label>
        </div>
        <div class="divContent" id="ctl00_BodyContent_divSheet">
            <div class="row">
                <div class="col-md-2" id="titledept">
                    <span id="Labeldept" data-type="SheetLabel" data-datafield="LRM_ApplyOrg">部门</span>
                </div>
                <div class="col-md-4" id="controldept">
                    <div id="ctl605262" data-type="SheetUser" data-datafield="LRM_ApplyOrg" data-orgunitvisible="true" data-uservisible="false" data-defaultvalue="{Originator.OU}" <%--onchange=" setTimeout('GetDeptUsers()',500);"--%>></div>
                </div>
                <div class="col-md-2" id="space2">
                </div>
                <div class="col-md-4" id="spaceControl2">
                </div>
            </div>
            <div class="row tableContent">
                <div class="col-md-2" id="title11">
                    <span id="Label17" data-type="SheetLabel" data-datafield="LeaveRequestDtl">请假申请明细表</span>
                </div>
                <div class="col-md-12" id="control11">
                    <div class="table-responsive">
                        <table class="table table-bordered table-condensed" id="Control17" data-type="SheetGridView" data-datafield="LeaveRequestDtl" data-defaultRowCount="0">
                            <tbody>
                                <tr class="header">
                                    <td class="rowSerialNo" id="Control17_SerialNo">序号
                                    </td>
                                    <td id="Control17_Header2" data-datafield="LeaveRequestDtl.LRD_Applicant">
                                        <label id="Control17_Label2" data-type="SheetLabel" data-datafield="LeaveRequestDtl.LRD_Applicant">工号</label>
                                    </td>
                                    <td id="Control17_Header3" data-datafield="LeaveRequestDtl.LRD_ApplicantName">
                                        <label id="Control17_Label3" data-type="SheetLabel" data-datafield="LeaveRequestDtl.LRD_ApplicantName">姓名</label>
                                    </td>
                                    <td id="Control17_Header4" data-datafield="LeaveRequestDtl.LRD_Type">
                                        <label id="Control17_Label4" data-type="SheetLabel" data-datafield="LeaveRequestDtl.LRD_Type">类型</label>
                                    </td>
                                    <td id="Control17_Header8" data-datafield="LeaveRequestDtl.LRD_Additional">
                                        <label id="Control17_Label8" data-type="SheetLabel" data-datafield="LeaveRequestDtl.LRD_Additional">是否补单</label>
                                    </td>
                                    <td id="Control17_Header5" data-datafield="LeaveRequestDtl.LRD_StartTime">
                                        <label id="Control17_Label5" data-type="SheetLabel" data-datafield="LeaveRequestDtl.LRD_StartTime">开始时间</label>
                                    </td>
                                    <td id="Control17_Header6" data-datafield="LeaveRequestDtl.LRD_EndTime">
                                        <label id="Control17_Label6" data-type="SheetLabel" data-datafield="LeaveRequestDtl.LRD_EndTime">结束时间</label>
                                    </td>
                                    <td id="Control17_Header7" data-datafield="LeaveRequestDtl.LRD_DayNum">
                                        <label id="Control17_Label7" data-type="SheetLabel" data-datafield="LeaveRequestDtl.LRD_DayNum">数量</label>
                                    </td>
                                    <td id="Control18_Header8" data-datafield="LeaveRequestDtl.LRD_Uom">
                                        <label id="Control18_Label8" data-type="SheetLabel" data-datafield="LeaveRequestDtl.LRD_Uom">单位</label>
                                    </td>
                                    <td id="Control17_Header9" data-datafield="LeaveRequestDtl.LRD_Reason">
                                        <label id="Control17_Label9" data-type="SheetLabel" data-datafield="LeaveRequestDtl.LRD_Reason">说明</label>
                                    </td>
                                    <td id="Control17_Header10" data-datafield="LeaveRequestDtl.LRD_Attachment">
                                        <label id="Control17_Label10" data-type="SheetLabel" data-datafield="LeaveRequestDtl.LRD_Attachment">附件</label>
                                    </td>
                                    <td class="rowOption" style="width: 45px;">删除</td>
                                    <td class="hidden record">考勤记录</td>
                                </tr>
                                <tr class="template">
                                    <td id="Control17_Option" style="text-align: center; width: 5%"></td>
                                    <td data-datafield="LeaveRequestDtl.LRD_Applicant" style="width: 8%; min-width: 100px; word-break: keep-all; white-space: nowrap;">
                                        <%--<div id="Control17_ctl3" data-type="SheetUser" data-datafield="LeaveRequestDtl.LRD_Applicant" data-onchange="GetData(this);"></div>--%>
                                        <input id="Control17_ctl2" type="text" data-type="SheetTextBox" data-datafield="LeaveRequestDtl.LRD_Applicant" autocomplete="off" data-onchange="GetData(this);" />
                                    </td>
                                    <td data-datafield="LeaveRequestDtl.LRD_ApplicantName" style="width: 8%; min-width: 100px; word-break: keep-all; white-space: nowrap;">
                                        <input id="Control17_ctl3" type="text" data-type="SheetTextBox" data-datafield="LeaveRequestDtl.LRD_ApplicantName" readonly="readonly" />
                                    </td>
                                    <td data-datafield="LeaveRequestDtl.LRD_Type" style="width: 10%; min-width: 100px;">
                                        <select id="ctl593968" data-type="SheetDropDownList" data-datafield="LeaveRequestDtl.LRD_Type" data-masterdatacategory="假期类型" data-onchange="var row = $(this).attr('data-row');&#10;GetALData(row);"></select>
                                        <%--<input id="Control17_ctl4" type="text" data-type="SheetTextBox" data-datafield="LeaveRequestDtl.LRD_Type" data-onchange="var row = $(this).attr('data-row');&#10;GetALData(row);" onclick="$('#modalBtn').click();">--%>
                                    </td>
                                    <td class="text-center" data-datafield="LeaveRequestDtl.LRD_Additional" style="width: 5%; min-width: 40px;">
                                        <input id="Control17_ctl8" type="checkbox" data-type="SheetCheckbox" data-datafield="LeaveRequestDtl.LRD_Additional" autocomplete="off" data-onchange="var row = $(this).attr('data-row');&#10;ValidateBunDan(row);">
                                    </td>
                                    <%--<td data-datafield="LeaveRequestDtl.LRD_StartTime" style="width: 14%; min-width: 170px">
                                        <input id="Control17_ctl5" type="text" data-type="SheetTime" data-datafield="LeaveRequestDtl.LRD_StartTime" autocomplete="off" data-toggle="tooltip" data-placement="top" title="开始时间小于当前时间，请先勾选补单" data-onchange="var row = $(this).attr('data-row');&#10;ValidateDateStart(row);" data-timemode="SimplifiedTime">
                                        <br>
                                        <label class="label label-info hidden al_info"></label>
                                    </td>--%>
                                    <td data-datafield="LeaveRequestDtl.LRD_StartTime" style="width: 14%; min-width: 170px">
                                        <input id="Control17_ctl5" type="text" data-type="SheetTextBox" data-datafield="LeaveRequestDtl.LRD_StartTime"  data-toggle="tooltip" data-placement="top" title="开始时间小于当前时间，请先勾选补单" data-onchange="var row = $(this).attr('data-row');&#10;ValidateDateStart(row);" data-timemode="SimplifiedTime" >
                                        <br>
                                        <label class="label label-info hidden al_info"></label>
                                    </td>
                                    <td data-datafield="LeaveRequestDtl.LRD_EndTime" style="width: 14%; min-width: 170px">
                                        <input id="Control17_ctl6" type="text" data-type="SheetTime" data-datafield="LeaveRequestDtl.LRD_EndTime" autocomplete="off" data-onchange="var row = $(this).attr('data-row');&#10;ValidateDateEnd(row);" data-timemode="SimplifiedTime" data-defaultvalue="">
                                    </td>
                                    <td data-datafield="LeaveRequestDtl.LRD_DayNum" style="width: 6%; min-width: 80px">
                                        <input id="Control18_ctl7" type="text" data-type="SheetTextBox" data-datafield="LeaveRequestDtl.LRD_DayNum" data-regularexpression="/^([1-9][0-9]*(\.5)?$)|(0\.5)$/" data-regularinvalidtext="请输入0.5的倍数." data-onchange="var row =$(this).attr('data-row');&#10;ValidateDateHours(row);" >
                                    </td>
                                    <td data-datafield="LeaveRequestDtl.LRD_Uom" style="width: 6%; min-width: 80px">
                                        <input id="Control17_ctl9" type="text" data-type="SheetTextBox" data-datafield="LeaveRequestDtl.LRD_Uom" readonly="readonly" data-defaultvalue="小时">
                                    </td>
                                    <td data-datafield="LeaveRequestDtl.LRD_Reason" style="width: 14%; min-width: 120px">
                                        <textarea id="ctl104175" style="width: 100%; height: 50%;" data-type="SheetRichTextBox" data-datafield="LeaveRequestDtl.LRD_Reason"></textarea>
                                    </td>
                                    <td data-datafield="LeaveRequestDtl.LRD_Attachment">
                                        <div id="Control17_ctl10" data-type="SheetAttachment" data-datafield="LeaveRequestDtl.LRD_Attachment">
                                        </div>
                                    </td>
                                    <td class="rowOption">
                                        <a class="delete">
                                            <div class="fa fa-minus">
                                            </div>
                                        </a>
                                        <a class="insert">
                                            <div class="fa fa-arrow-down">
                                            </div>
                                        </a>
                                    </td>
                                    <td data-datafield="record" class="hidden record" style="min-width: 140px">
                                        <div class="daysoffList hidden"><a href="javascript:;" class="btn btn-link">查看调休假明细</a></div>
                                        <div class="recordList"></div>
                                    </td>
                                </tr>
                                <tr class="footer">
                                    <td></td>
                                    <td data-datafield="LeaveRequestDtl.LRD_Applicant"></td>
                                    <td data-datafield="LeaveRequestDtl.LRD_ApplicantName"></td>
                                    <td data-datafield="LeaveRequestDtl.LRD_Type"></td>
                                    <td data-datafield="LeaveRequestDtl.LRD_Additional"></td>
                                    <td data-datafield="LeaveRequestDtl.LRD_StartTime"></td>
                                    <td data-datafield="LeaveRequestDtl.LRD_EndTime"></td>
                                    <td data-datafield="LeaveRequestDtl.LRD_DayNum"></td>
                                    <td data-datafield="LeaveRequestDtl.LRD_Uom"></td>
                                    <td data-datafield="LeaveRequestDtl.LRD_Reason"></td>
                                    <td data-datafield="LeaveRequestDtl.LRD_Attachment"></td>
                                    <td class="rowOption"></td>
                                    <td class="hidden record"></td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
            <div class="row tableContent">
                <div class="col-md-2" id="title1">
                    <span id="Label11" data-type="SheetLabel" data-datafield="LRM_Approve">直属上司审核</span>
                </div>
                <div class="col-md-10" id="control1">
                    <div id="Control11" data-type="SheetComment" data-datafield="LRM_Approve"></div>
                </div>
            </div>
            <div class="row tableContent">
                <div class="col-md-2" id="title3">
                    <span id="Label12" data-type="SheetLabel" data-datafield="LRM_ManagerApp">部门主管批准</span>
                </div>
                <div class="col-md-10" id="control3">
                    <div id="Control12" data-type="SheetComment" data-datafield="LRM_ManagerApp"></div>
                </div>
            </div>
            <div class="row tableContent">
                <div class="col-md-2" id="title5">
                    <span id="Label13" data-type="SheetLabel" data-datafield="LRM_HrCheck">人事核对</span>
                </div>
                <div class="col-md-10" id="control5">
                    <div id="Control13" data-type="SheetComment" data-datafield="LRM_HrCheck"></div>
                </div>
            </div>
            <div class="row hidden">
                <div class="col-md-2" id="title7">
                    <span id="Label14" data-type="SheetLabel" data-datafield="LRM_AppResult">直接上司审核结果</span>
                </div>
                <div class="col-md-4" id="control7">
                    <input id="Control14" type="text" data-type="SheetTextBox" data-datafield="LRM_AppResult">
                </div>
                <div class="col-md-2" id="title8">
                    <span id="Label15" data-type="SheetLabel" data-datafield="LRM_MgrAppResult">部门主管审批结果</span>
                </div>
                <div class="col-md-4" id="control8">
                    <input id="Control15" type="text" data-type="SheetTextBox" data-datafield="LRM_MgrAppResult">
                </div>
            </div>
            <div class="row hidden">
                <div class="col-md-2" id="title9">
                    <span id="Label16" data-type="SheetLabel" data-datafield="LRM_HrChkResult">人事核对结果</span>
                </div>
                <div class="col-md-4" id="control9">
                    <input id="Control16" type="text" data-type="SheetTextBox" data-datafield="LRM_HrChkResult">
                </div>
                <div class="col-md-2" id="space10">
                </div>
                <div class="col-md-4" id="spaceControl10">
                </div>
            </div>
        </div>
        <div class="hidden">
            <button id="modalBtn" type="button" class="btn btn-primary" data-toggle="modal" data-target="#myModal">点击弹窗</button>
        </div>
        <!-- 模态弹出窗 -->
        <div class="modal fade" id="myModal">
            <div class="modal-dialog">
                <div class="modal-content" style="min-width:650px;min-height:650px;">
                <!-- 模态弹出窗内容 -->
                    <div class="modal-header">
                        <button type="button" class="close" data-dismiss="modal"><span aria-hidden="true">&times;</span><span class="sr-only">Close</span></button>
                        <h3 class="modal-title">填写请假信息</h3>
                    </div>
                    <div class="modal-body" style="margin:5px;min-height:500px;">
                        <div style="border:1px solid #ddd;">
                            <label class="radio" style="font-size:20px;"><b>类型：</b></label>
                            <div class="radio-inline" style="padding:8px;margin:0px 20px;width:90%;">
                                <label class="radio-inline" style="margin:0px 30px;font-size:18px;">
                                  <input type="radio" name="holType" value="DaysOff" />调休
                                </label>
                                <label class="radio-inline" style="margin:0px 30px;font-size:18px;">
                                  <input type="radio" name="holType" value="AnnualLeave" />年假
                                </label>
                                <label class="radio-inline" style="margin:0px 30px;font-size:18px;">
                                  <input type="radio" name="holType" value="PersonalLeave" />事假
                                </label>
                                <label class="radio-inline" style="margin:0px 30px;font-size:18px;">
                                  <input type="radio" name="holType" value="InjuryLeave" />工伤假
                                </label>
                            </div>
                            <div class="radio-inline" style="padding:8px;margin:0px 20px;width:90%;">
                                <label class="radio-inline" style="margin:0px 30px;font-size:18px;">
                                  <input type="radio" name="holType" value="MaternityLeave" />产假
                                </label>
                                <label class="radio-inline" style="margin:0px 30px;font-size:18px;">
                                  <input type="radio" name="holType" value="MaritalLeave" />婚假
                                </label>
                                <label class="radio-inline" style="margin:0px 30px;font-size:18px;">
                                  <input type="radio" name="holType" value="SickLeave" />病假
                                </label>
                                <label class="radio-inline" style="margin:0px 30px;font-size:18px;">
                                  <input type="radio" name="holType" value="CompassionateLeave" />恩恤假
                                </label>
                            </div>
                        </div>
                        <div style="border:1px solid #ddd;margin-top:30px;">
                            <label class="radio" style="font-size:20px;"><b>班别：</b></label>
                            <div class="radio-inline" style="padding:8px;margin:0px 20px;width:90%;">
                                <label class="radio-inline" style="margin:0px 30px;font-size:18px;">
                                  <input type="radio" name="shift" value="morningShift" />早班
                                </label>
                                <label class="radio-inline" style="margin:0px 30px;font-size:18px;">
                                  <input type="radio" name="shift" value="middleShift" />中班
                                </label>
                                <label class="radio-inline" style="margin:0px 30px;font-size:18px;">
                                  <input type="radio" name="shift" value="nightShift" />晚班
                                </label>
                                <label class="radio-inline" style="margin:0px 30px;font-size:18px;">
                                  <input type="radio" name="shift" value="normalShift" />正常班
                                </label>
                            </div>
                        </div>
                        <div style="border:1px solid #ddd;margin-top:30px;">
                            <label class="" style="font-size:20px;margin-left:20px;"><b>时间：</b></label>
                            <div class="" style="padding:8px;margin:0px 20px;width:90%;display:block;">
                                <label style="margin:0px 5px 0px 30px;font-size:18px;">开始时间:</label>
                                <input style="width:135px;" type="text" id="startTime" name="startTime" onclick="WdatePicker({ dateFmt: 'yyyy-MM-dd HH:mm', minDate: '2010-01-01 00:00', maxDate: '2050-12-31 23:59' })" />
                                <label style="margin:0px 5px 0px 30px;font-size:18px;">结束时间:</label>
                                <input style="width:135px;" type="text" id="endTime" name="endTime" onclick="WdatePicker({ dateFmt: 'yyyy-MM-dd HH:mm', minDate: '2010-01-01 00:00', maxDate: '2050-12-31 23:59' })"/>
                            </div>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-default" data-dismiss="modal">取消</button>
                        <button type="button" class="btn btn-primary" onclick="save();">确认</button>
                    </div>
                </div>
            </div>
        </div>

    </div>
</asp:Content>