/**
 * VOLP Assignment Due Alert Script
 * How to run:
 * VOLP_USERNAME=[emailprefix]@vit.edu VOLP_PASSWORD=REPLACE NOTIFY_API_URL=OPTIONAL node assignments_alerter.js
 *
 * If Password is not provided, it will use the username as password.
 *
 * for best results, set this up as a daily cron job: "0 12,21 * * *"    (12 PM and 9 PM daily)
 **/

const LOGIN_URL = "https://admin.volp.in/login/process";
const COURSE_LIST_URL =
  "https://learner.volp.in/learnerCourseDashboard/learnerCourseList";
const ASSIGNMENT_URL =
  "https://learner.volp.in/SubjectiveAssignment/getSubjectiveAssignment_new";
const NEAR_DUE_HOURS = 48; // only for within next 48 hours, coz why care about later ones when you can do them later

let { VOLP_USERNAME, VOLP_PASSWORD, NOTIFY_API_URL } = process.env;

if (!VOLP_USERNAME) {
  console.error("Missing required environment variable: VOLP_USERNAME");
  process.exit(1);
}

if (!VOLP_PASSWORD) VOLP_PASSWORD = VOLP_USERNAME;
const VOLP_UID = VOLP_USERNAME;

function parseDueDate(dueStr) {
  if (!dueStr || dueStr === "NA") return null;

  const [datePart, timePart, ampm] = dueStr.split(" ");
  const [day, month, year] = datePart.split("/").map(Number);
  const [hourRaw, minute] = timePart.split(":").map(Number);

  let hour = hourRaw;
  if (ampm === "PM" && hour !== 12) hour += 12;
  if (ampm === "AM" && hour === 12) hour = 0;

  return new Date(year, month - 1, day, hour, minute);
}

function isNearDue(date) {
  if (!date) return false;
  const now = new Date();
  const diffMs = date - now;
  const diffHours = diffMs / (1000 * 60 * 60);
  return diffHours > 0 && diffHours <= NEAR_DUE_HOURS;
}

function parseDueDate(dueStr) {
  if (!dueStr || dueStr === "NA") return null;

  try {
    const [datePart, timePart] = dueStr.split(" ");
    const [day, month, year] = datePart.split("/").map(Number);
    const [hour, minute] = timePart.split(":").map(Number);
    return new Date(year, month - 1, day, hour, minute);
  } catch (err) {
    console.error("Failed parsing date:", dueStr);
    return null;
  }
}

async function notify(htmlMessage) {
  if (!NOTIFY_API_URL) return;
  const payload = { message: htmlMessage, isHtml: true };

  const res = await fetch(NOTIFY_API_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(payload),
  });

  if (!res.ok) {
    console.error(`Notification failed: ${res.status} ${await res.text()}`);
  } else {
    console.log("Notification sent successfully.");
  }
}

async function login() {
  const res = await fetch(LOGIN_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json;charset=utf-8",
      device: "Web",
      "router-path": "/login",
      "organization-code": "null",
    },
    body: JSON.stringify({
      username: VOLP_USERNAME,
      pwd: VOLP_PASSWORD,
    }),
  });

  const data = await res.json();

  if (data.status !== "200" || data.flag == "NO") {
    throw new Error(`Login failed: ${data.msg || "Unknown error"}`);
  }

  return data.token;
}

async function fetchCourses(token) {
  const res = await fetch(COURSE_LIST_URL, {
    method: "POST",
    headers: {
      token: token,
      uid: VOLP_UID,
      ut: "Learner",
      device: "Web",
      "router-path": "/learner/my-courses",
      "organization-code": "null",
    },
  });

  const data = await res.json();
  if (data.status !== "200") {
    throw new Error("Failed to fetch courses");
  }

  return data.col_list || [];
}

async function fetchAssignments(token, course) {
  const res = await fetch(ASSIGNMENT_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json;charset=utf-8",
      token: token,
      uid: VOLP_UID,
      ut: "Learner",
      device: "Web",
      "router-path": "/learner-subjective-assignment",
      "organization-code": "null",
    },
    body: JSON.stringify({
      course_offering_learner_id: course.colid,
      type: "content",
      courseId: course.crsid,
    }),
  });

  const data = await res.json();
  if (!data.question_list) return [];
  return data.question_list;
}

async function main() {
  try {
    console.log("Logging in...");
    const token = await login();

    console.log("Fetching courses...");
    const courses = await fetchCourses(token);

    const alerts = [];

    for (const course of courses) {
      if (!course.status) continue; // skip inactive

      console.log(`Checking course: ${course.code}`);

      const assignments = await fetchAssignments(token, course);

      for (const a of assignments) {
        const dueDate = parseDueDate(a.due_date);

        const notSubmitted =
          a.isalreadysubmitted === "false" || a.issubmitted === false;

        if (notSubmitted && isNearDue(dueDate)) {
          alerts.push({
            course: course.code,
            title: stripHtml(a.question),
            due: a.due_date,
          });
        }
      }
    }

    if (alerts.length === 0) {
      console.log("No upcoming assignments.");
      return;
    }

    if (!NOTIFY_API_URL) {
      console.log(
        "\n============================================================",
      );
      console.log("ASSIGNMENT ALERT REPORT");
      console.log(
        "============================================================\n",
      );

      if (!alerts.length) {
        console.log(
          "🎉 ALL CLEAR! No upcoming assignments within the defined threshold.\n",
        );
        return;
      }

      const now = new Date();

      const grouped = alerts.reduce((acc, a) => {
        if (!acc[a.course]) acc[a.course] = [];
        acc[a.course].push(a);
        return acc;
      }, {});

      let total = 0;

      for (const course of Object.keys(grouped)) {
        console.log(`COURSE: ${course}`);
        console.log(
          "------------------------------------------------------------",
        );

        for (const a of grouped[course]) {
          const dueDate = parseDueDate(a.due);
          const diffMs = dueDate.getTime() - Date.now();
          const hoursLeft = Math.floor(diffMs / (1000 * 60 * 60));

          console.log(`Title       : ${a.title}`);
          console.log(`Due         : ${a.due}`);

          if (isNaN(hoursLeft)) {
            console.log(`Time Left   : Unable to compute`);
          } else {
            console.log(`Time Left   : ${hoursLeft} hours`);
          }
          console.log("");
          total++;
        }

        console.log("");
      }

      console.log(
        "============================================================",
      );
      console.log(`TOTAL UPCOMING ASSIGNMENTS: ${total}`);
      console.log(
        "============================================================\n",
      );

      return;
    }

    let htmlMessage = `
  <div style="font-family: Arial, sans-serif; background:#f8fafc; padding:20px;">
    <div style="max-width:600px;margin:auto;background:white;border-radius:8px;padding:20px;">
      <h2 style="color:#dc2626;margin-top:0;">Assignment Due Alert</h2>
      <p style="color:#475569;">
        The following assignments are due within ${NEAR_DUE_HOURS} hours:
      </p>
`;

    for (const a of alerts) {
      htmlMessage += `
    <div style="border:1px solid #e2e8f0;border-radius:6px;padding:12px;margin-bottom:12px;">
      <p style="margin:0 0 6px 0;"><strong>Course:</strong> ${a.course}</p>
      <p style="margin:0 0 6px 0;"><strong>Title:</strong> ${a.title}</p>
      <p style="margin:0;color:#b91c1c;"><strong>Due:</strong> ${a.due}</p>
    </div>
  `;
    }

    htmlMessage += `
      <p style="font-size:12px;color:#64748b;margin-top:20px;">
        Generated automatically by VOLP Assignment Monitor.
      </p>
    </div>
  </div>
`;

    await notify(htmlMessage);
  } catch (err) {
    console.error("Error:", err.message);
  }
}

function stripHtml(html) {
  if (!html) return "";
  return html
    .replace(/<[^>]*>/g, "")
    .replace(/\s+/g, " ")
    .trim();
}

main();
