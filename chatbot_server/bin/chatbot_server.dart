import 'dart:convert';
import 'dart:io';
import 'package:hexaminate/hexaminate.dart';
import 'package:hive/hive.dart';

void main() async {
  var getCurrentPath = Directory.current;
  Hive.init("${getCurrentPath.path}/db");
  Box box = await Hive.openBox("database");
  Server app = Server();
  app.on("/", (RequestApi req, ResponseApi res) async {
    return res.send("api normal");
  });
  app.post("/ask", (RequestApi req, ResponseApi res) async {
    Map? body;
    try {
      body = await req.body;
    } catch (e) {
      body = {};
      return res.code(400).send({"ok": false, "message": "error parse body as json"});
    }
    if (body is Map && body.isNotEmpty) {
      var language_code = "id";
      var question = "";
      if (body["language_code"] is String && (body["language_code"] as String).isNotEmpty) {
        language_code = body["language_code"];
      }
      if (body["question"] is String && (body["question"] as String).isNotEmpty) {
        question = body["question"];
      } else {
        return res.code(400).send({
          "ok": false,
          "message": "please add key question as string",
        });
      }
      var getDataChatbot = box.get(language_code, defaultValue: []);
      if (getDataChatbot is List) {
        if (getDataChatbot.isEmpty) {
          return res.code(404).send({
            "ok": false,
            "message": "your question $question not found in database please try again later",
          });
        }
        for (var i = 0; i < getDataChatbot.length; i++) {
          var loop_data = getDataChatbot[i];
          if (loop_data is Map && loop_data.isNotEmpty) {
            if (loop_data["question"] is String) {
              if (RegExp(loop_data["question"], caseSensitive: false).hasMatch(question)) {
                return res.send({"ok": true, "result": loop_data});
              }
            }
          }
        }
        return res.code(404).send({
          "ok": false,
          "message": "your question $question not found in database please try again later",
        });
      } else {
        return res.code(400).send({
          "ok": false,
          "message": "database error please contact administrator",
        });
      }
    }
    return res.code(400).send({"ok": false, "message": "body json is empy please send again"});
  });
  app.post("/add", (RequestApi req, ResponseApi res) async {
    Map? body;
    try {
      body = await req.body;
    } catch (e) {
      body = {};
      return res.code(400).send({"ok": false, "message": "error parse body as json"});
    }
    if (body is Map && body.isNotEmpty) {
      var language_code = "id";

      var question = "";
      var answer = "";
      if (body["language_code"] is String && (body["language_code"] as String).isNotEmpty) {
        language_code = body["language_code"];
      } else {
        return res.code(400).send({
          "ok": false,
          "message": "please add key language_code as string",
        });
      }
      if (body["question"] is String && (body["question"] as String).isNotEmpty) {
        question = body["question"];
      } else {
        return res.code(400).send({
          "ok": false,
          "message": "please add key question as string",
        });
      }

      if (body["answer"] is String && (body["answer"] as String).isNotEmpty) {
        answer = body["answer"];
      } else {
        return res.code(400).send({
          "ok": false,
          "message": "please add key answer as string",
        });
      }

      var getDataChatbot = box.get(language_code, defaultValue: []);
      if (getDataChatbot is List) {
        for (var i = 0; i < getDataChatbot.length; i++) {
          var loop_data = getDataChatbot[i];
          if (loop_data is Map && loop_data.isNotEmpty) {
            if (loop_data["question"] is String) {
              if (RegExp(loop_data["question"], caseSensitive: false).hasMatch(question)) {
                getDataChatbot[i]["question"] = question;
                getDataChatbot[i]["answer"] = answer;
                box.put(language_code, getDataChatbot);
                return res.send({
                  "ok": true,
                  "result": {"status": "succes update data chatbot"}
                });
              }
            }
          }
        }
        getDataChatbot.add({"question": question, "answer": answer});
        box.put(language_code, getDataChatbot);
        return res.send({
          "ok": true,
          "result": {"status": "succes add new data chatbot"}
        });
      } else {
        return res.code(400).send({
          "ok": false,
          "message": "database error please contact administrator",
        });
      }
    }
    return res.code(400).send({"ok": false, "message": "body json is empy please send again"});
  });

  app.listen(callback: (HttpServer server) {}, port: 8080, host: "0.0.0.0");
}
