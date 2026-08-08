exports.handler = async (event) => {
  console.log("Evento recibido de S3:", JSON.stringify(event, null, 2));

  for (const record of event.Records ?? []) {
    const bucket = record.s3.bucket.name;
    const key = decodeURIComponent(record.s3.object.key.replace(/\+/g, " "));
    console.log(`Nuevo objeto subido: s3://${bucket}/${key}`);
  }

  return { statusCode: 200 };
};
