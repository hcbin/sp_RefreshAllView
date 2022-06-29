-- 刷新全部视图
IF NOT EXISTS(SELECT name FROM SYS.PROCEDURES WHERE [object_id]=OBJECT_ID('sp_RefreshAllView') AND TYPE='P')
BEGIN
  EXEC('
CREATE PROCEDURE [DBO].[sp_RefreshAllView]
AS
BEGIN
  DECLARE C_View CURSOR FOR
    SELECT DISTINCT s.name + ''.'' + v.name AS ViewName
      FROM SYS.VIEWS AS v
        INNER JOIN SYS.SCHEMAS AS s ON v.[schema_id]=s.[schema_id] 
      WHERE v.[type]=''V''
        AND OBJECTPROPERTY(v.[object_id], ''IsSchemaBound'')<>1
        AND OBJECTPROPERTY(v.[object_id], ''IsMsShipped'')<>1
      ORDER BY 1;

  DECLARE @view VARCHAR(60);
  OPEN C_View;

  FETCH NEXT FROM C_View INTO @view;
  WHILE @@fetch_status=0
  BEGIN
    BEGIN TRY
      BEGIN TRANSACTION;
        EXEC SP_REFRESHVIEW @view;
        -- PRINT ''[SUCCESS]'' + @view;
      COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
      IF (XACT_STATE()) = -1  
      BEGIN
        PRINT ''[ERROR]'' + @view;
        PRINT ''错误如下：'';
        PRINT ERROR_MESSAGE();

        IF(ERROR_SEVERITY()=16 AND ERROR_STATE()=6)
          PRINT ''建议复制代码重建视图'';

        PRINT '''';  -- 空出一行

        -- SELECT ERROR_NUMBER() AS Number, ERROR_SEVERITY() AS Severity, ERROR_STATE() AS [State], ERROR_PROCEDURE() AS [Procedure], ERROR_LINE() AS Line, ERROR_MESSAGE() AS [Message], @view AS [View];
        ROLLBACK TRANSACTION;  
      END;
    END CATCH

    FETCH NEXT FROM C_View INTO @view;
  END;

  CLOSE C_View;
  DEALLOCATE C_View;
END;
  ')
END;
GO

EXEC sp_RefreshAllView;
GO